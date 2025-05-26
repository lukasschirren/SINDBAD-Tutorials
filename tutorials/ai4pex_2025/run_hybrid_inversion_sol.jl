# ================================== using tools ==================================================
# some of the things that will be using... Julia tools, SINDBAD tools, local codes...
using Revise
using SindbadTutorials
using SindbadML

# ================================== get data / set paths ========================================= 
# data to be used can be found here: https://nextcloud.bgc-jena.mpg.de/s/w2mbH59W4nF3Tcd
# organizing the paths of data sources and outputs for this experiment
path_input_dir      = getSindbadDataDepot(; env_data_depot_var="SINDBAD_DATA_DEPOT", 
                    local_data_depot=joinpath(@__DIR__,"..","..","data","ai4pex_2025")); # for convenience, the data file is set within the SINDBAD-Tutorials path; this needs to be changed otherwise.
path_input          = joinpath("$(path_input_dir)","FLUXNET_v2023_12_1D_REPLACED_Noise003.zarr"); # zarr data source containing all the data for site level runs
path_observation    = path_input; # observations (synthetic or otherwise) are included in the same file
path_covariates     = joinpath("$(path_input_dir)","CovariatesFLUXNET_3.zarr"); # zarr data source containing all the covariates
path_output         = "";

# ================================== setting up the experiment ====================================
# experiment is all set up according to a (collection of) json file(s)
path_experiment_json = joinpath(@__DIR__,"..","ai4pex_2025","settings_WROASTED_HB","experiment_hybrid.json")

replace_info = Dict(
    "forcing.default_forcing.data_path" => path_input,
    "optimization.observations.default_observation.data_path" => path_observation,
    "optimization.optimization_cost_threaded" => false,
    "optimization.optimization_parameter_scaling" => nothing,
);

info = getExperimentInfo(path_experiment_json; replace_info=replace_info);

forcing = getForcing(info);
observations = getObservation(info, forcing.helpers);
sites_forcing = forcing.data[1].site;

hybrid_helpers = prepHybrid(forcing, observations, info, info.hybrid.ml_training.method);

trainML(hybrid_helpers, info.hybrid.ml_training.method)

## play around with gradient for sites and batch to understand internal workings
ml_model = hybrid_helpers.ml_model;
xfeatures = hybrid_helpers.features.data;
loss_functions = hybrid_helpers.loss_functions;
loss_component_functions = hybrid_helpers.loss_component_functions;

params_sites = ml_model(xfeatures)
@info "params_sites: [$(minimum(params_sites)), $(maximum(params_sites))]"

scaled_params_sites = getParamsAct(params_sites, info.optimization.parameter_table)
@info "scaled_params_sites: [$(minimum(scaled_params_sites)), $(maximum(scaled_params_sites))]"


## try for a site
site_index = 1
site_name = sites_forcing[site_index]

loc_params = scaled_params_sites(site=site_name).data.data
loss_f_site = loss_functions(site=site_name);
loss_vector_f_site = loss_component_functions(site=site_name);
@time loss_f_site(loc_params)
loss_vector_f_site(loc_params)

@time g_site = gradientSite(info.hybrid.ml_gradient.method, loc_params, info.hybrid.ml_gradient.options, loss_functions(site=site_name))

## try for a batch
sites_batch = hybrid_helpers.sites.training[1:info.hybrid.ml_training.options.batch_size]
scaled_params_batch = scaled_params_sites(; site=sites_batch)
grads_batch = zeros(Float32, size(scaled_params_batch, 1), length(sites_batch));

g_batch = gradientBatch!(info.hybrid.ml_gradient.method, grads_batch, info.hybrid.ml_gradient.options, loss_functions, scaled_params_batch, sites_batch; showprog=true)
