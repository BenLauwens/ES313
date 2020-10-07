using Printf

function print_header(data::Data)
    if data.verbosity == 1
        @printf("Iter \t  Objective  \t Inf Linear \t Radius \t Gradient res \t D[end, end] \t AC\n")
    elseif data.verbosity == 2
        @printf("Iter \t  Objective  \t Inf Linear \t Radius \t Gradient res \t D[end, end] \t AC\t\t ||LDL'-Z'PZ||   ||Q*Q'-I|| \t ||Q1*R1-A1||\n")
    end
end

function print_info(data::Data)
    if data.verbosity == 1
        @printf("%d \t  %.5e \t %.5e \t %.5e \t %s \t %.5e \t %d/%d   \n",
            data.iteration,
            0.5*data.x'*data.F.P*data.x + dot(data.q, data.x),
            max(maximum(data.A*data.x - data.b), 0),
            norm(data.x),
            isnan(data.residual) ? string(@sprintf("%.5e", data.residual), "   ") : @sprintf("%.5e", data.residual),
            length(data.F.D) > 0 ? data.F.D[end] : NaN,
            length(data.working_set),
            data.F.artificial_constraints
        )
    elseif data.verbosity == 2
        @printf("%d \t  %.5e \t %.5e \t %.5e \t %s \t %.5e \t %d/%d    \t %.5e \t %.5e \t %.5e\n",
            data.iteration,
            0.5*data.x'*data.F.P*data.x + dot(data.q, data.x),
            max(maximum(data.A*data.x - data.b), 0),
            norm(data.x),
            isnan(data.residual) ? string(@sprintf("%.5e", data.residual), "   ") : @sprintf("%.5e", data.residual),
            length(data.F.D) > 0 ? data.F.D[end] : NaN,
            length(data.working_set),
            data.F.artificial_constraints,
            norm(data.F.U'*data.F.D*data.F.U - data.F.Z'*data.F.P*data.F.Z),
            norm(data.F.QR.Q'*data.F.QR.Q - I),
            norm(data.F.QR.Q1*data.F.QR.R1 - data.A[data.working_set, :]'),
        ) 
    end
end