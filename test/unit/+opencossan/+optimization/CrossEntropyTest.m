classdef CrossEntropyTest < matlab.unittest.TestCase
    %CROSSENTROPYTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        OptimizationProblem;
    end
    
    methods (TestMethodSetup)
        function setupOptimizationProblem(testCase)
            x1 = opencossan.optimization.ContinuousDesignVariable('upperbound', 5, ...
                'lowerBound', -5);
            x2 = opencossan.optimization.ContinuousDesignVariable('upperbound', 5, ...
                'lowerBound', -5);
            input = opencossan.common.inputs.Input('names',["x1" "x2"], 'members',{x1 x2});
            
            objfun = opencossan.optimization.ObjectiveFunction('Description','objective function', ...
                'FunctionHandle', @(x) (x(:,1).^2 + x(:,2) - 11).^2 + (x(:,1) + x(:,2).^2 -7).^2, ...
                'OutputNames',{'y'},...
                'IsFunction', true, ...
                'format', 'matrix', ...
                'InputNames',{'x1' 'x2'});
            
            s = rng(); rng(46354);
            testCase.addTeardown(@rng, s);
            testCase.OptimizationProblem = opencossan.optimization.OptimizationProblem(...
                'Input',input,'ObjectiveFunction',objfun, 'initialsolution', unifrnd(-5,5,40,2));
        end
    end
    
    methods (Test)
        % constructor
        function constructorEmpty(testCase)
            ce = opencossan.optimization.CrossEntropy();
            testCase.assertClass(ce, 'opencossan.optimization.CrossEntropy');
        end
        
        function constructorFull(testCase)
            ce = opencossan.optimization.CrossEntropy('NFunEvalsIter',40,'NUpdate',10, ...
                'SigmaTolerance', 1e-4);
            testCase.assertClass(ce, 'opencossan.optimization.CrossEntropy');
            testCase.assertEqual(ce.NFunEvalsIter, 40);
            testCase.assertEqual(ce.NUpdate, 10);
            testCase.assertEqual(ce.SigmaTolerance, 1e-4);
        end
        
        % apply
        function shouldFindOptimum(testCase)
            ce = opencossan.optimization.CrossEntropy('NFunEvalsIter',40,'NUpdate',20);
            optimum = testCase.OptimizationProblem.optimize('optimizer', ce);
            
            testCase.assertEqual(optimum.OptimalSolution, [3, 2], 'RelTol', 1e-3);
        end
    end
end

