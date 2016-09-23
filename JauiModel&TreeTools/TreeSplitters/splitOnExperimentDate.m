function V = splitOnExperimentDate(epoch)
    V = datestr(datetime(epoch.cell.experiment.startDate'));
end
