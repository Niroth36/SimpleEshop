// This is a wrapper script that handles the repository checkout properly
// before executing the main pipeline
node {
    // Clean workspace
    cleanWs()
    echo '✅ Workspace cleaned'

    // Checkout the repository explicitly
    checkout([
        $class: 'GitSCM',
        branches: [[name: '*/master']],
        doGenerateSubmoduleConfigurations: false,
        extensions: [],
        submoduleCfg: [],
        userRemoteConfigs: [[
            url: 'https://github.com/Niroth36/SimpleEshop.git',
            credentialsId: 'github-token'
        ]]
    ])

    // Now run the main pipeline
    load 'Jenkinsfile.main'
}

// The script ends here. The actual pipeline is loaded from Jenkinsfile.main
