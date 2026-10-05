function build_model(root,c)
name='smart_grid_fault_detection';
if bdIsLoaded(name), close_system(name,0); end
new_system(name);
set_param(name,'Solver','FixedStepDiscrete','FixedStep',num2str(1/c.fs,17),'StopTime',num2str(c.duration),'ReturnWorkspaceOutputs','on');
add_block('simulink/Sources/Digital Clock',[name '/Sample clock'],'SampleTime',num2str(1/c.fs,17),'Position',[15 100 55 140]);
add_block('simulink/User-Defined Functions/MATLAB System',[name '/Feeder voltage and current'],'System','GridFeeder','SimulateUsing','Interpreted execution','Position',[100 95 245 145]);
add_block('simulink/User-Defined Functions/MATLAB System',[name '/AI fault classifier'],'System','FaultDetector','SimulateUsing','Interpreted execution','Position',[305 90 480 150]);
add_block('simulink/Sinks/To Workspace',[name '/Predictions'],'VariableName','prediction','SaveFormat','Timeseries','Position',[550 80 690 120]);
add_block('simulink/Sinks/Scope',[name '/Fault ID and vote confidence'],'Position',[555 155 690 205]);
add_block('simulink/Sinks/To Workspace',[name '/Electrical measurements'],'VariableName','measurements','SaveFormat','Timeseries','Position',[285 220 460 260]);
add_line(name,'Sample clock/1','Feeder voltage and current/1','autorouting','on');
add_line(name,'Feeder voltage and current/1','AI fault classifier/1','autorouting','on');
add_line(name,'AI fault classifier/1','Predictions/1','autorouting','on');
add_line(name,'AI fault classifier/1','Fault ID and vote confidence/1','autorouting','on');
add_line(name,'Feeder voltage and current/1','Electrical measurements/1','autorouting','on');
Simulink.Annotation(name,sprintf('Three-phase R-L feeder measurements -> causal 1-cycle features -> bagged decision trees\nRun run_project.m first. Fault IDs: 1 Normal, 2 AG, 3 BG, 4 CG, 5 AB, 6 BC, 7 CA, 8 ABG, 9 BCG, 10 CAG, 11 ABC'));
save_system(name,fullfile(root,'models',[name '.slx']));
print(['-s' name],'-dpng','-r150',fullfile(root,'results','simulink_model.png'));
end
