# #------------------------------------------------------------------------------------------------------------------
# #------------------------------------------------------------------------------------------------------------------
# # This file contains functions used for creating and running the Nested Inequalities Climate Economy (NICE) model.
# #------------------------------------------------------------------------------------------------------------------
# #------------------------------------------------------------------------------------------------------------------



#####################################################################################################################
# CALCULATE DAMAGE AND CO₂ MITIGATION COST DISTRIBUTIONS ACROSS QUINTILES.
#####################################################################################################################
# Description: This function will calculate quintile distribution shares for the RICE regions based
#			   on a user-supplied income elasticity.
#
# Function Arguments:
#
#       elasticity    = Income elasticity of climate damages, mitigation costs, etc.
#	    income_shares = An array of quintile income shares (row = quintile, column = RICE region).
#--------------------------------------------------------------------------------------------------------------------

function quintile_distribution(elasticity, income_shares)

	# Apply elasticity to quintile income shares.
    scaled_shares = income_shares .^ elasticity

    # Allocate empty array for distribution across quintiles resulting from the elasticity.
    updated_distribution = zeros(5,12)

    # Loop through each RICE region to calculate updated distributions.
    for r in 1:12
        updated_distribution[:,r] = scaled_shares[:,r] ./ sum(scaled_shares[:,r])
    end

    return updated_distribution
end
