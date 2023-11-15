include("factory_simulation_2.jl")

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

function ReadParameters(file_path::String)
    
end
P = read_parameters("parameters.csv")

# file directory and name; * concatenates strings.
dir = pwd()*"/data/"*"/seed"*string(P.seed) # directory name
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
