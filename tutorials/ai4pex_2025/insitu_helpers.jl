
export getSiteInfo, getSpinupSequenceSite, getIndicesForPFT
using SindbadTutorials

function getSiteInfo(site_index)
    site_info = CSV.File(joinpath(@__DIR__, "settings_WROASTED_HB/site_names_disturbance.csv"); header=true)
    domain = string(site_info[site_index][1])
    y_dist = string(site_info[site_index][2])
    return domain, y_dist
end


function getIndicesForPFT(; pft=[])
    site_info = CSV.File(joinpath(@__DIR__, "settings_WROASTED_HB/site_names_disturbance_pft.csv"); header=true)
    site_indices = 1:length(site_info)
    if !isempty(pft)
        site_indices = findall(in(pft), site_info.pft)
    end
    return site_indices
end

function getSpinupSequenceSite(y_dist, begin_year; nrepeat=200)
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


