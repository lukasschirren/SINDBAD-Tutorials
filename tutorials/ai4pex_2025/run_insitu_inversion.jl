using Revise
using SindbadTutorials
using SindbadTutorials.Dates
using SindbadTutorials.Plots
toggleStackTraceNT()
include("insitu_helpers.jl")
# site_index = Base.parse(Int, ENV["SLURM_ARRAY_TASK_ID"])

# site info
site_index = 10
domain, y_dist = get_site_info(site_index);


# experiment info
experiment_json = "../ai4pex_2025/settings_WROASTED_HB/experiment_insitu.json"
experiment_name = "WROASTED_inversion_CMAES"
begin_year = 1979
end_year = 2017
run_optimization = true

# experiment paths
path_input = "$(getSindbadDataDepot())/FLUXNET_v2023_12_1D.zarr"
path_observation = path_input;
path_output = ""

spinup_sequence = get_spinup_sequence(y_dist, begin_year)

replace_info = Dict("experiment.basics.time.date_begin" => "$(begin_year)-01-01",
    "experiment.basics.domain" => domain,
    "experiment.basics.name" => experiment_name,
    "experiment.basics.time.date_end" => "$(end_year)-12-31",
    "experiment.flags.run_optimization" => run_optimization,
    "experiment.model_spinup.sequence" => spinup_sequence,
    "forcing.default_forcing.data_path" => path_input,
    "forcing.subset.site" => [site_index, site_index],
    "experiment.model_output.path" => path_output,
    "optimization.observations.default_observation.data_path" => path_observation,)


@time out_opti = runExperimentOpti(experiment_json; replace_info=replace_info, log_level=:info);

plot_obs_figures(out_opti)
plot_debug_figures(out_opti.info, out_opti.output.optimized, out_opti.output.default)