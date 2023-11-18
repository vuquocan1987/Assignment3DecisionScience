using Test
include("factory_simulation_2.jl") # Replace with the actual path to your simulation code file

### Unit Tests

# Test for Order creation
@testset "Order Creation Tests" begin
    order = Order(1, 5.0)
    @test order.id == 1
    @test order.arrival_time ≈ 5.0
    @test length(order.start_service_times) == n_servers
    @test order.completion_time == Inf
end

# Test for SystemState initialization
@testset "SystemState Initialization Tests" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    state = SystemState(params)
    @test state.time == 0.0
    @test state.n_entities == 0
    @test state.n_events == 0
    @test length(state.order_queues) == n_servers
    @test all(isnothing, state.in_service)
end

# Test for Random Number Generators
@testset "Random Number Generators Tests" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    rngs = RandomNGs(params)
    @test rngs.interarrival_time() > 0
    @test rngs.machine_times[1]() > 0
    @test rngs.machine_times[2]() > 0
end

### Integration Tests

# Test for Event Processing
@testset "Event Processing Tests" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    (system, rngs) = initialise(params)
    
    # Test Arrival Event
    arrival_event = Arrival(1, 5.0)
    update!(system, params, rngs, arrival_event)
    @test length(system.order_queues[1]) == 0

    # Test Finish Event
    finish_event = Finish(2, 6.0, 1)
    update!(system, params, rngs, finish_event)
    @test isnothing(system.in_service[1])
end


@testset "Queue 2 Full Test" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    (system, rngs) = initialise(params)

    # Fill Queue 2
    for i in 1:params.max_queue[2]
        enqueue!(system.order_queues[2], Order(i, system.time))
    end

    # Finish event at Machine 1 when Queue 2 is full
    # add an arrival event to queue 1
    arrival_event = Arrival(1, 5.0)
    update!(system, params, rngs, arrival_event)
    finish_event = Finish(1, 6.0, 1)
    update!(system, params, rngs, finish_event)

    @test length(system.order_queues[2]) == params.max_queue[2]  # Queue 2 should still be full
    @test !isnothing(system.in_service[1])  # Machine 1 should not proceed to the next order
end

@testset "Finish Event at Machine 2 Test" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    (system, rngs) = initialise(params)

    # Process an order at Machine 2
    order = Order(1, system.time)
    system.in_service[2] = order
    system.n_entities += 1

    
    # Finish processing the order at Machine 2
    finish_event = Finish(2, system.time, 2)
    order = update!(system, params, rngs, finish_event)
    @test isnothing(system.in_service[2])  # Machine 2 should be free
    @test order.completion_time ≈ system.time  # Order should be marked as completed
end

@testset "Sequential Order Processing Test" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    (system, rngs) = initialise(params)

    # Process first order in Machine 1
    order1 = Order(1, system.time)
    system.in_service[1] = order1
    system.n_entities += 1

    # Finish event for first order in Machine 1
    finish_event1 = Finish(1, system.time, 1)
    update!(system, params, rngs, finish_event1)

    # Process second order in Machine 1
    order2 = Order(2, system.time)
    system.in_service[1] = order2
    system.n_entities += 1

    # Finish event for second order in Machine 1
    finish_event2 = Finish(2, system.time, 1)
    update!(system, params, rngs, finish_event2)

    @test length(system.order_queues[2]) == 1  # 1 order should be in Queue 2
    @test isnothing(system.in_service[1])  # Machine 1 should be free
    @test !isnothing(system.in_service[2])  # Check that Machine 2 is busy
end

@testset "Machine 1 Idle with Empty Queue Test" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    (system, rngs) = initialise(params)

    # Process and finish an order in Machine 1
    order = Order(1, system.time)
    system.in_service[1] = order
    system.n_entities += 1
    finish_event = Finish(1, system.time, 1)
    update!(system, params, rngs, finish_event)

    # Ensure no new orders in Queue 1
    @test isempty(system.order_queues[1])
    @test isnothing(system.in_service[1])  # Machine 1 should be idle
end

# Test for Full Simulation Run
@testset "Full Simulation Run Test" begin
    params = Parameters(123, 1000.0, 1.5, [2.0, 3.0], [4, 4], "hours", 0.5)
    (system, rngs) = initialise(params)
    run!(system, params, rngs, IOBuffer(), IOBuffer())
    @test system.time <= params.T+2000
    @test system.n_entities > 0
end