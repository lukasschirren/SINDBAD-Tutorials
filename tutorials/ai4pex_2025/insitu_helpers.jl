
export get_site_info, get_spinup_sequence
export plot_obs_figures, plot_debug_figures
using SindbadTutorials

function get_site_info(site_index)
    site_info = CSV.File(joinpath(@__DIR__,
            "settings_WROASTED_HB/site_names_disturbance.csv");
        header=true)
    domain = string(site_info[site_index][1])
    y_dist = string(site_info[site_index][2])
    return domain, y_dist
end


function get_spinup_sequence(y_dist, begin_year; nrepeat=200)
    nrepeat_d = nothing
    if y_dist != "undisturbed"
        y_disturb = year(Date(y_dist))
        y_start = begin_year
        nrepeat_d = y_start - y_disturb
    end
    if isnothing(nrepeat_d) || nrepeat_d < 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
            Dict("spinup_mode" => "eta_scale_AHCWD", "forcing" => "day_MSC", "n_repeat" => 1),
        ]
    elseif nrepeat_d == 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
            Dict("spinup_mode" => "eta_scale_A0HCWD", "forcing" => "day_MSC", "n_repeat" => 1),
        ]
    elseif nrepeat_d > 0
        sequence = [
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "all_years", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat),
            Dict("spinup_mode" => "eta_scale_A0HCWD", "forcing" => "day_MSC", "n_repeat" => 1),
            Dict("spinup_mode" => "sel_spinup_models", "forcing" => "day_MSC", "n_repeat" => nrepeat_d),
        ]
    else
        error("cannot determine the repeat for disturbance")
    end
    return sequence
end



function plot_obs_figures(out_opti)
    opt_dat = out_opti.output.optimized
    def_dat = out_opti.output.default
    obs_array = out_opti.observation
    info = out_opti.info
    costOpt = prepCostOptions(obs_array, info.optimization.cost_options)
    default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))

    fig_prefix = joinpath(info.output.dirs.figure, "comparison_" * info.experiment.basics.name * "_" * info.experiment.basics.domain)

    foreach(costOpt) do var_row
        v = var_row.variable
        println("plot obs:: $v")
        v = (var_row.mod_field, var_row.mod_subfield)
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        v = vinfo["standard_name"]
        lossMetric = var_row.cost_metric
        loss_name = nameof(typeof(lossMetric))
        if loss_name in (:NNSEInv, :NSEInv)
            lossMetric = NSE()
        end
        valids = var_row.valids
        (obs_var, obs_σ, def_var) = getData(def_dat, obs_array, var_row)
        (_, _, opt_var) = getData(opt_dat, obs_array, var_row)
        obs_var_TMP = obs_var[:, 1, 1, 1]
        non_nan_index = findall(x -> !isnan(x), obs_var_TMP)
        if length(non_nan_index) < 2
            tspan = 1:length(obs_var_TMP)
        else
            tspan = first(non_nan_index):last(non_nan_index)
        end

        obs_σ = obs_σ[tspan]
        obs_var = obs_var[tspan]
        def_var = def_var[tspan, 1, 1, 1]
        opt_var = opt_var[tspan, 1, 1, 1]
        valids = valids[tspan]

        xdata = [info.helpers.dates.range[tspan]...]

        metr_def = metric(obs_var[valids], obs_σ[valids], def_var[valids], lossMetric)
        metr_opt = metric(obs_var[valids], obs_σ[valids], opt_var[valids], lossMetric)

        plot(xdata, obs_var; label="obs", seriestype=:scatter, mc=:black, ms=4, lw=0, ma=0.65, left_margin=1Plots.cm)
        plot!(xdata, def_var, lw=1.5, ls=:dash, left_margin=1Plots.cm, legend=:outerbottom, legendcolumns=3, label="def ($(round(metr_def, digits=2)))", size=(2000, 1000), title="$(domain): $(vinfo["long_name"]) ($(vinfo["units"])) -> $(nameof(typeof(lossMetric)))", color=:steelblue2)
        plot!(xdata, opt_var; color=:seagreen3, label="opt ($(round(metr_opt, digits=2)))", lw=1.5, ls=:dash)
        savefig(fig_prefix * "_$(v).png")
    end

    return nothing
end

function plot_debug_figures(info, opt_dat, def_dat)

    # plot debug figures
    output_array_opt = values(opt_dat)
    output_array_def = values(def_dat)
    output_vars = info.output.variables

    default(titlefont=(20, "times"), legendfontsize=18, tickfont=(15, :blue))
    fig_prefix = joinpath(info.output.dirs.figure, "debug_" * info.experiment.basics.name * "_" * info.experiment.basics.domain)
    for (o, v) in enumerate(output_vars)
        def_var = output_array_def[o][:, :, 1, 1]
        opt_var = output_array_opt[o][:, :, 1, 1]
        vinfo = getVariableInfo(v, info.experiment.basics.temporal_resolution)
        v = vinfo["standard_name"]
        println("plot debug::", v)
        xdata = [info.helpers.dates.range...]
        if size(opt_var, 2) == 1
            plot(xdata, def_var[:, 1]; label="def ($(round(SindbadTEM.mean(def_var[:, 1]), digits=2)))", size=(2000, 1000), title="$(vinfo["long_name"]) ($(vinfo["units"]))", left_margin=1Plots.cm, color=:steelblue2)
            plot!(xdata, opt_var[:, 1], color=:seagreen3; label="opt ($(round(SindbadTEM.mean(opt_var[:, 1]), digits=2)))")
            ylabel!("$(vinfo["standard_name"])", font=(20, :green))
            savefig(fig_prefix * "_$(v).png")
        else
            foreach(axes(opt_var, 2)) do ll
                plot(xdata, def_var[:, ll]; label="def ($(round(SindbadTEM.mean(def_var[:, ll]), digits=2)))", size=(2000, 1000), title="$(domain): $(vinfo["long_name"]), layer $(ll),  ($(vinfo["units"]))", left_margin=1Plots.cm, color=:steelblue2)
                plot!(xdata, opt_var[:, ll]; color=:seagreen3, label="opt ($(round(SindbadTEM.mean(opt_var[:, ll]), digits=2)))")
                ylabel!("$(vinfo["standard_name"])", font=(20, :green))
                savefig(fig_prefix * "_$(v)_$(ll).png")
            end
        end
    end
    return nothing
end