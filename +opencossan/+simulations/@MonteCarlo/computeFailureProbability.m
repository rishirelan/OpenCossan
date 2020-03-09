function pf = computeFailureProbability(obj, model)
    %COMPUTEFAILUREPROBABILITY method. This method compute the FailureProbability associate to a
    % ProbabilisticModel/SystemReliability/MetaModel by means of a Monte Carlo
    % simulation object. It returns a FailureProbability object.
    %
    % See also:
    % https://cossan.co.uk/wiki/index.php/computeFailureProbability@Simulation
    %
    % Author: Edoardo Patelli
    % Institute for Risk and Uncertainty, University of Liverpool, UK
    % email address: openengine@cossan.co.uk
    % Website: http://www.cossan.co.uk
    
    % =====================================================================
    % This file is part of openCOSSAN.  The open general purpose matlab
    % toolbox for numerical analysis, risk and uncertainty quantification.
    %
    % openCOSSAN is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License.
    %
    % openCOSSAN is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    %  You should have received a copy of the GNU General Public License
    %  along with openCOSSAN.  If not, see <http://www.gnu.org/licenses/>.
    % =====================================================================
    
    
    import opencossan.*
    import opencossan.reliability.*
    
    if ~isempty(obj.RandomStream)
        prevstream = RandStream.setGlobalStream(obj.RandomStream);
    end
        
    obj.StartTime = tic;
    simData = opencossan.common.outputs.SimulationData();
    batch = 0;
    
    while true
        batch = batch + 1;
        
        classname = split(metaclass(obj).Name, '.');
        classname = classname{end};
        opencossan.OpenCossan.cossanDisp(...
            sprintf("[%s] Batch #%i (%i samples)", classname, batch, obj.NumberOfSamples), 3);
        
        samples = obj.sample('samples',obj.NumberOfSamples,'input',model.Input);
        
        simDataBatch = model.apply(samples);
        simDataBatch.Samples.Batch = repmat(batch, simDataBatch.NumberOfSamples, 1);
        
        simData = simData + simDataBatch;
        
        performance = simData.Samples.(model.PerformanceFunctionVariable);
        pf = sum(performance < 0) / height(simData.Samples);
        variance = (pf - pf^2) / height(simData.Samples);
        
        % check termination
        [exit, flag] = obj.checkTermination('batch', batch, 'cov', sqrt(variance) * pf);
        
        if exit
            simData.ExitFlag = flag;
            break;
        end
    end
    
    pf = FailureProbability('value', pf, 'variance', variance, 'simulationdata', simData, 'simulation', obj);
    
    if ~isempty(obj.RandomStream)
        RandStream.setGlobalStream(prevstream);
    end
    
    if ~isdeployed
        % add entries in simulation and analysis database at the end of the
        % computation when not deployed. The deployed version does this with
        % the finalize command
        XdbDriver = opencossan.OpenCossan.getDatabaseDriver;
        if ~isempty(XdbDriver)
            XdbDriver.insertRecord('StableType','Result',...
                'Nid',getNextPrimaryID(OpenCossan.getDatabaseDriver,'Result'),...
                'CcossanObjects',{Xpf},...
                'CcossanObjectsNames',{'Xpf'});
        end
    end
end

