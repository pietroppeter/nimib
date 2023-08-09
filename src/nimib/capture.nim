## This submodule implements only one template to temporarily redirect and capture stdout during execution of a chunk of code.
import fusion/ioutils
import std/os
import std/tempfiles

template captureStdout*(ident: untyped, filename: string, body: untyped) =
    ## redirect stdout to a temporary file and captures output of body in ident
    # Duplicate stdout
    let stdoutFileno: FileHandle = stdout.getFileHandle()
    let stdoutDupFd: FileHandle = stdoutFileno.duplicate()
    
    # Create a new temporary file or attempt to open it
    let (tmpFile, tmpFileName {.used.}) = if filename == "":
            createTempFile("tmp", "")
        else:
            let tmpName = getTempDir() / filename
            (tmpName.open(fmAppend), tmpName)
    let tmpFileFd: FileHandle = tmpFile.getFileHandle() 
    
    # writing to stdoutFileno now writes to tmpFile
    tmpFileFd.duplicateTo(stdoutFileno)
    
    # Execute body code
    body
    
    # Flush stdout and tmpFile, read tmpFile from start to ident and then close tmpFile
    stdout.flushFile()
    tmpFile.flushFile()
    if filename == "":
        tmpFile.setFilePos(0)
    else:
        discard tmpFile.reopen(tmpFileName)
    ident = tmpFile.readAll()
    tmpFile.close()
    
    # Restore stdout
    stdoutDupFd.duplicateTo(stdoutFileno)

template captureStdout*(ident: untyped, body: untyped) =
    captureStdout(ident, "", body)
