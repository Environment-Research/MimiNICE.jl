@defcomp nice_welfare begin

    regions      = Index()                                     # Index for RICE regions.
    quintiles    = Index()                                     # Index for regional income quintiles.

    eta          = Parameter()                                 # Elasticity of marginal utility of consumption.
    rho          = Parameter()                                 # Pure rate of time preference.
    quintile_pop = Parameter(index=[time, regions])            # Quintile population levels for each region.
    quintile_c   = Parameter(index=[time, regions, quintiles]) # Post-damage, post-abatement cost quintile consumption (thousands 2005 USD yr⁻¹).

    welfare    = Variable()                                    # Total economic welfare.


    function run_timestep(p, v, d, t)

        if is_first(t)
            # Calculate period 1 welfare.
            v.welfare = sum((p.quintile_c[t,:,:] .^ (1.0 - p.eta)) ./ (1.0 - p.eta) .* p.quintile_pop[t,:]) / (1.0 + p.rho)^(10*(t.t-1))
        else
            # Calculate cummulative welfare over time.
            v.welfare = v.welfare + sum((p.quintile_c[t,:,:] .^ (1.0 - p.eta)) ./ (1.0 - p.eta) .* p.quintile_pop[t,:]) / (1.0 + p.rho)^(10*(t.t-1))
        end
    end
end
