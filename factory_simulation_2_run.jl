include("factory_simulation_2.jl")
using CSV, DataFrames
# inititialise
# seed = 1
# T = 10_000.0
# mean_interarrival = 60.0 ###    units here are minutes
# mean_machine_times = [25.0, 59.0]
# max_queue = [typemax(Int64), 4]
# time_units = "minutes"
# std_machine_1 = 7.185832891717325
# P = Parameters( seed, T, mean_interarrival, mean_machine_times, max_queue, time_units,std_machine_1)

# read parameter from a separate csv file
function read_parameters(filepath::String, seeds_range::UnitRange{Int64}, T::Int64=10_000)
    # Read the parameters from the specified CSV file into a DataFrame.
    # The first row is assumed to contain the column headers.
    df = CSV.read(filepath, DataFrame)
    
    # Initialize an array to hold Parameters objects.
    Ps = Parameters[]
    
    # Iterate over the range of seed values and rows of the DataFrame to create Parameters objects.
    for seed in seeds_range
        for row in eachrow(df)
            # Extract parameters from the current row.
            mean_machine_times = [row.mean_machine_time_1, row.mean_machine_time_2]
            max_queue = [row.max_queue_1, row.max_queue_2   ]
            # Create a new Parameters object with the extracted values and the current seed.
            P = Parameters(
                seed,
                T,
                row.mean_interarrival,
                mean_machine_times,
                max_queue,
                row.time_units,
                row.std_machine_1
            )
            # Add the new Parameters object to the array.
            push!(Ps, P)
        end
    end
    
    # Return the array of Parameters objects.
    return Ps
end

# P = read_parameters("parameters.csv")

# file directory and name; * concatenates strings.
# put a timer on the simulation
function get_simulation_dir(P::Parameters)
    return "$(pwd())/data/mean_interarrival_$(P.mean_interarrival)/max_queue_1_$(P.max_queue[1])/max_queue_2_$(P.max_queue[2])/mean_machine_time_1$(P.mean_machine_times[1])/mean_machine_time_2$(P.mean_machine_times[2])/std_machine_1_$(P.std_machine_1)"
end

function run_simulations(T::Int64, seed_range::UnitRange{Int64}, parameter_path::String)
    Ps = read_parameters(parameter_path, seed_range, T)
    for P in Ps
        # dir = pwd()*"/data/"*"/seed"*string(P.seed) # directory name
        dir = "$(get_simulation_dir(P))/seed$(P.seed)"
        mkpath(dir)                          # this creates the directory 
        file_entities = dir*"/entities.csv"  # the name of the data file (informative) 
        file_state = dir*"/state.csv"        # the name of the data file (informative) 
        fid_entities = open(file_entities, "w") # open the file for writing
        fid_state = open(file_state, "w")       # open the file for writing
    
        write_metadata( fid_entities )
        write_metadata( fid_state )
        write_parameters( fid_entities, P )
        write_parameters( fid_state, P )
    
        # headers
        write_entity_header( fid_entities,  Order(0, 0.0) )
        println(fid_state,"time,event_id,event_type,timing,length_event_list,length_queue1,length_queue2,in_service1,in_service2")
    
        # run the actual simulation
        (system,R) = initialise( P ) 
        run!( system, P, R, fid_state, fid_entities)
    
        # remember to close the files
        close( fid_entities )
        close( fid_state )
    
    end
end




function performance_test(Ts::Vector{Int64})
    for T in Ts
        @time run_simulations(T, 2:2, "parameters.csv")
    end
end
run_simulations(200000, 2:1000, "Parameters.CSV")
# generate a list of Ts 10, 20, 40 by code0