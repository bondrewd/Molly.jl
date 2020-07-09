# Different ways to simulate molecules

export
    simulate!,
    VelocityVerlet,
    VelocityFreeVerlet

"""
    VelocityVerlet()

The velocity Verlet integrator.
"""
struct VelocityVerlet <: Simulator end

"""
    simulate!(simulation; parallel=true)
    simulate!(simulation, n_steps; parallel=true)
    simulate!(simulation, simulator, n_steps; parallel=true)

Run a simulation according to the rules of the given simulator.
Custom simulators should implement this function.
"""
function simulate!(s::Simulation,
                    ::VelocityVerlet,
                    n_steps::Integer;
                    parallel::Bool=true)
    # See https://www.saylor.org/site/wp-content/uploads/2011/06/MA221-6.1.pdf for
    #   integration algorithm - used shorter second version
    n_atoms = length(s.coords)
    neighbours = find_neighbours(s, nothing, s.neighbour_finder, 0,
                                    parallel=parallel)
    accels_t = accelerations(s, neighbours, parallel=parallel)
    accels_t_dt = zero(s.coords)

    @showprogress for step_n in 1:n_steps
        for logger in values(s.loggers)
            log_property!(logger, s, step_n)
        end

        # Update coordinates
        for i in 1:length(s.coords)
            s.coords[i] += s.velocities[i] * s.timestep + accels_t[i] * (s.timestep ^ 2) / 2
            s.coords[i] = adjust_bounds.(s.coords[i], s.box_size)
        end

        accels_t_dt = accelerations(s, neighbours, parallel=parallel)

        # Update velocities
        for i in 1:length(s.velocities)
            s.velocities[i] += (accels_t[i] + accels_t_dt[i]) * s.timestep / 2
        end

        apply_thermostat!(s, s.thermostat)
        neighbours = find_neighbours(s, neighbours, s.neighbour_finder, step_n,
                                        parallel=parallel)

        accels_t = accels_t_dt
        s.n_steps_made[1] += 1
    end
    return s
end

"""
    VelocityFreeVerlet()

The velocity-free Verlet integrator, also known as the Störmer method.
In this case the `velocities` given to the `Simulator` act as the previous step
coordinates for the first step.
"""
struct VelocityFreeVerlet <: Simulator end

function simulate!(s::Simulation,
                    ::VelocityFreeVerlet,
                    n_steps::Integer;
                    parallel::Bool=true)
    n_atoms = length(s.coords)
    neighbours = find_neighbours(s, nothing, s.neighbour_finder, 0,
                                    parallel=parallel)
    coords_last = s.velocities

    @showprogress for step_n in 1:n_steps
        for logger in values(s.loggers)
            log_property!(logger, s, step_n)
        end

        accels_t = accelerations(s, neighbours, parallel=parallel)

        # Update coordinates
        coords_copy = s.coords
        for i in 1:length(s.coords)
            s.coords[i] = 2 * s.coords[i] - coords_last[i] + accels_t[i] * s.timestep ^ 2
            s.coords[i] = adjust_bounds.(s.coords[i], s.box_size)
        end
        coords_last = coords_copy

        apply_thermostat!(s, s.thermostat)
        neighbours = find_neighbours(s, neighbours, s.neighbour_finder, step_n,
                                        parallel=parallel)

        s.n_steps_made[1] += 1
    end
    return s
end

function simulate!(s::Simulation, n_steps::Integer; parallel::Bool=true)
    simulate!(s, s.simulator, n_steps, parallel=parallel)
end

function simulate!(s::Simulation; parallel::Bool=true)
    simulate!(s, s.n_steps - first(s.n_steps_made), parallel=parallel)
end
