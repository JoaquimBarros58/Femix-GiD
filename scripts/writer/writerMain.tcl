# This procedure writes the main parameters to file.
proc Writer::MainParameters {} {
    Writer::WriteLine <MAIN_PARAMETERS> 1

    set path {/*/container[@n="main_parameters"]//value[@n="main_title"]}
    Writer::WriteLine "MAIN_TITLE = [SpdAux::GetValue $path] ;" 2
    Writer::WriteLine

    # Analyse type parameters
    set path {/*/container[@n="main_parameters"]//value[@n="analysis_type"]}
    Writer::WriteLine "ANALYSIS_TYPE = [SpdAux::GetTag $path] ;" 2
    # Material nonlinearities parameters
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'nlprob' \]/value\[@n = 'mat_nonlinear_prob' \]"
    set mat [SpdAux::GetValue $path]
    Writer::WriteLine "MATERIALLY_NONLINEAR_PROBLEM = [SpdAux::GetTagYesNo $path] ;" 2
    # Geomtric nonlinearities parameters
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'nlprob' \]/value\[@n = 'geo_nonlinear_prob' \]"
    set geo [SpdAux::GetValue $path]
    Writer::WriteLine "GEOMETRICALLY_NONLINEAR_PROBLEM = [SpdAux::GetTagYesNo $path] ;" 2
    Writer::WriteLine

    set path "container\[@n = 'main_parameters' \]/container\[@n = 'phases' \]/value\[@n = 'num_phases' \]"
    Writer::WriteLine "NUMBER_OF_PHASES = [SpdAux::GetValue $path] ;" 2
    Writer::WriteLine "NUMBER_OF_LOAD_CASES = [SpdAux::GetNumLoadCases] ;" 2
    Writer::WriteLine "NUMBER_OF_COMBINATIONS = 0 ;" 2
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'arcl' \]/value\[@n = 'activate' \]"
    set arc [SpdAux::GetValue $path]
    # Only prints arc lenght if the nonlinear analysis is enabled.
    if {$mat == "Yes" && $arc == "Yes"} { 
        set path "container\[@n = 'main_parameters' \]/container\[@n = 'arcl' \]/value\[@n = 'max' \]"
        Writer::WriteLine "MAXIMUM_NUMBER_OF_ARC_LENGTH_COMBINATIONS = [SpdAux::GetValue $path] ;" 2
    }
    Writer::WriteLine

    # ---------------------------------------
    # Matrix storage and solver parameters
    # ---------------------------------------
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'storage' \]/value"
    Writer::WriteLine "STIFFNESS_MATRIX_STORAGE_TECHNIQUE = [SpdAux::GetTag "$path\[@n = 'technique' \]"] ;" 2
    
    if {[SpdAux::GetValue "$path\[@n = 'technique' \]"] == "SYMMETRIC_NONCONSTANT_SEMIBAND"} { 
        Writer::WriteLine "SYSTEM_LIN_EQ_ALGORITHM = _GAUSS_ELIM ;" 2
    } else { 
        Writer::WriteLine "SYSTEM_LIN_EQ_ALGORITHM = [SpdAux::GetTag "$path\[@n = 'system' \]"] ;" 2
        Writer::WriteLine "PRECONDITIONED_RESIDUAL_DECAY = [SpdAux::GetTag "$path\[@n = 'decay' \]"] ;" 2
        Writer::WriteLine
    }

    # ---------------------------------------
    # Nonlinear parameters
    # ---------------------------------------
    if {$mat == "Yes" || $geo == "Yes"} { 
        set path "container\[@n = 'main_parameters' \]/container\[@n = 'nlprob' \]/value"
        Writer::WriteLine "ITERATIVE_ALGORITHM = [SpdAux::GetTag "$path\[@n = 'iter_algor' \]"] ;" 2
        Writer::WriteLine "CONVERGENCE_CRITERION = [SpdAux::GetTag "$path\[@n = 'conv_criterion' \]"] ;" 2
        Writer::WriteLine "TOLERANCE_IN_EACH_COMBINATION = [SpdAux::GetValue "$path\[@n = 'tol_comb' \]"] ;" 2
        Writer::WriteLine "MAXIMUM_NUMBER_OF_ITERATIONS_IN_EACH_COMBINATION = [SpdAux::GetValue "$path\[@n = 'max_comb' \]"] ;" 2
        Writer::WriteLine "NUMBER_OF_COMBINATIONS_BEFORE_RESTART = [SpdAux::GetValue "$path\[@n = 'restart' \]"] ;" 2
        Writer::WriteLine "LINE_SEARCH = [SpdAux::GetTagYesNo "$path\[@n = 'line_search' \]"] ;" 2
        Writer::WriteLine "PATH_BEHAVIOR = [SpdAux::GetTag "$path\[@n = 'path_behavior' \]"] ;" 2
    }

    if {$mat == "Yes" && $arc == "Yes"} { 
        Writer::WriteLine "ARC_LENGTH = _Y ;" 2
    }

    Writer::WriteLine </MAIN_PARAMETERS> 1
    Writer::WriteLine
}