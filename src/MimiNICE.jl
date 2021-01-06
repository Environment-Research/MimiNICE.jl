module MimiNICE

# Load required packages.
using CSVFiles, DataFrames, Mimi, MimiRICE2010


# Load helper functions and NICE components being added to the RICE model.
include("helper_functions.jl")
include(joinpath("nice_components", "nice_neteconomy_component.jl"))
include(joinpath("nice_components", "nice_welfare_component.jl"))

# Export the following functions.
export create_nice, quintile_distribution


# ---------------------------------------------
# ---------------------------------------------
# Create function to build NICE.
# ---------------------------------------------
# ---------------------------------------------

function create_nice()

    #----------------------#
    #----- Load Data ----- #
    #----------------------#

    # Load updated UN population projections and convert units to millions of people.
    un_population_data = convert(Matrix, DataFrame(load(joinpath(@__DIR__, "..", "data", "UN_medium_population_scenario.csv"), skiplines_begin=3))[:, 3:end]) ./ 1000

    # Calculate quintile population levels for each region.
    quintile_population = un_population_data ./ 5

    # Load quintile income distribution data.
    income_distribution = convert(Matrix, DataFrame(load(joinpath(@__DIR__, "..", "data", "quintile_income_shares.csv"), skiplines_begin=2))[:,2:end])

    #--------------------------------#
    #----- Build NICE from RICE----- #
    #--------------------------------#

    # Initialize NICE as an instance of RICE2010.
    nice = MimiRICE2010.get_model()

    # Set income quintile model dimension.
    set_dimension!(nice, :quintiles, ["First", "Second", "Third", "Fourth", "Fifth"])

    # Calculate default number of model timesteps in RICE.
    n_steps = length(dim_keys(nice, :time))

    # Delete RICE net_economy and welfare components.
    delete!(nice, :neteconomy)
    delete!(nice, :welfare)

    # Add in NICE's net economy and welfare components.
    add_comp!(nice, nice_neteconomy, after = :damages)
    add_comp!(nice, nice_welfare,    after = :nice_neteconomy)

    #------------------------------------#
    #----- Assign Model Parameters ----- #
    #------------------------------------#

    # Update/set already existing RICE parameters.
    set_param!(nice, :dk,  ones(12))
    set_param!(nice, :MIU, zeros(n_steps, 12))
    set_param!(nice, :S,   ones(n_steps, 12) .* 0.2585)
    set_param!(nice, :l,   un_population_data)

    # Set new NICE component parameters for net economy.
    set_param!(nice, :nice_neteconomy, :income_dist, income_distribution ./ 100)
    set_param!(nice, :nice_neteconomy, :damage_dist, quintile_distribution(1.0, income_distribution))
    set_param!(nice, :nice_neteconomy, :abatement_dist, quintile_distribution(1.0, income_distribution))

    # Set new NICE component parameters for welfare component.
    set_param!(nice, :nice_welfare, :quintile_pop, quintile_population)
    set_param!(nice, :nice_welfare, :rho, 0.015)
    set_param!(nice, :nice_welfare, :eta, 1.5)

    # Create model connections.
    connect_param!(nice, :grosseconomy,    :I,          :nice_neteconomy, :I)
    connect_param!(nice, :nice_neteconomy, :YGROSS,     :grosseconomy,    :YGROSS)
    connect_param!(nice, :nice_neteconomy, :DAMFRAC,    :damages,         :DAMFRAC)
    connect_param!(nice, :nice_neteconomy, :ABATECOST,  :emissions,       :ABATECOST)
    connect_param!(nice, :nice_welfare,    :quintile_c, :nice_neteconomy, :quintile_c_post)

    # Return NICE model.
    return nice
end

end # module
