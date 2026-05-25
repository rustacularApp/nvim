function nvim {
    # Convert current Windows path to a format Docker understands
    $currentDir = (Get-Item .).FullName.Replace('\', '/').Replace('C:', '//c')
    
    # Run the container, mount the directory, and clean up on exit
    docker run --rm -it `
        -v "${currentDir}:/workspace" `
        -w /workspace `
        docker-nvim nvim $args
}
