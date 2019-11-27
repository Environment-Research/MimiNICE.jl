@defcomp nice_neteconomy begin

    regions         = Index()                                    # Index for RICE regions.
    quintiles       = Index()                                    # Index for regional income quintiles.

    YGROSS          = Parameter(index=[time, regions])           # Gross economic output (trillions 2005 USD yr⁻¹).
    DAMFRAC         = Parameter(index=[time, regions])           # Climate damages as share of gross output.
    ABATECOST       = Parameter(index=[time, regions])           # Cost of CO₂ emission reductions (trillions 2005 USD yr⁻¹).
    S               = Parameter(index=[time, regions])           # Savings rate as share of gross economic output.
    l               = Parameter(index=[time, regions])           # Regional population (millions).
    income_dist     = Parameter(index=[quintiles, regions])      # Quintile share of regional income.
    damage_dist     = Parameter(index=[quintiles, regions])      # Quintile share of regional climate damages.
    abatement_dist  = Parameter(index=[quintiles, regions])      # Quintile share of regional CO₂ abatement costs.

    Y               = Variable(index=[time, regions])            # Gross world product net of abatement and damages (trillions 2005 USD yr⁻¹).
    I               = Variable(index=[time, regions])            # Investment (trillions 2005 USD yr⁻¹).
    C               = Variable(index=[time, regions])            # Regional consumption (trillions 2005 US dollars yr⁻¹).
    CPC             = Variable(index=[time, regions])            # Regional per capita consumption (thousands 2005 USD yr⁻¹)
    ABATEFRAC       = Variable(index=[time, regions])            # Cost of CO₂ emission reductions as share of gross economic output.
    quintile_c_pre  = Variable(index=[time, regions, quintiles]) # Pre-damage, pre-abatement cost quintile consumption (thousands 2005 USD yr⁻¹).
    quintile_c_post = Variable(index=[time, regions, quintiles]) # Post-damage, post-abatement cost quintile consumption (thousands 2005 USD yr⁻¹).


    function run_timestep(p, v, d, t)

        for r in d.regions

            # MimiRICE2010 calculates abatement cost in dollars. Divide by YGROSS to get abatement as share of output.
            v.ABATEFRAC[t,r] = p.ABATECOST[t,r] ./ p.YGROSS[t,r]

            # Calculate net economic output following Equation 2 in Dennig et al. (PNAS 2015).
            v.Y[t,r] = (1.0 - v.ABATEFRAC[t,r]) / (1.0 + p.DAMFRAC[t,r]) * p.YGROSS[t,r]

            # Investment.
            v.I[t,r] = p.S[t,r] * v.Y[t,r]

            # Regional consumption (RICE assumes no investment in final period).
            if t.t != 60
                v.C[t,r] = v.Y[t,r] - v.I[t,r]
            else
                v.C[t,r] = v.C[t-1, r]
            end

            # Regional per capita consumption.
            v.CPC[t,r] = 1000 * v.C[t,r] / p.l[t,r]

            # Create a temporary variable to calculate quintile consumption (just for convenience).
            temp_C = 5.0 * v.CPC[t,r] * (1.0 + p.DAMFRAC[t,r]) / (1.0 - v.ABATEFRAC[t,r])

            for q in d.quintiles
                # Calculate pre-damage, pre-abatement cost quintile consumption.
                v.quintile_c_pre[t,r,q] = temp_C * p.income_dist[q,r]

                # Calculate post-damage, post-abatement cost quintile consumption (bounded below to ensure consumptions don't collapse to zero or go negative).
                v.quintile_c_post[t,r,q] = max(v.quintile_c_pre[t,r,q] - (5.0 * v.CPC[t,r] * p.DAMFRAC[t,r] * p.damage_dist[q,r]) - (temp_C * v.ABATEFRAC[t,r] * p.abatement_dist[q,r]), 1e-8)
            end
        end
    end
end
