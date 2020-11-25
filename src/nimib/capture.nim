## This submodule implements only one template to temporarily redirect and capture stdout during execution of a chunk of code.
import tempfile

# see https://stackoverflow.com/questions/64026829/how-to-temporarily-capture-stdout
# Thanks, Clonk!

# low level, should be Posix only but they happen to work on (my) Windows, too!
proc dup(oldfd: FileHandle): FileHandle {.importc, header: "unistd.h".}
proc dup2(oldfd: FileHandle, newfd: FileHandle): cint {.importc, header: "unistd.h".}

template captureStdout*(ident: untyped, body: untyped) =
  ## redirect stdout to a temporary file and captures output of body in ident
  let
    # Duplicate stdout
    stdoutFileno = stdout.getFileHandle()
    stdoutDupfd = dup(stdoutFileno)
    # Create a new temporary file
    (tmpFile, tmpFilename) = mkstemp(mode=fmWrite)
    tmpFileFd: FileHandle = tmpFile.getFileHandle()  
  discard dup2(tmpFileFd, stdoutFileno)  # writing to stdoutFileno now writes to tmpFile

  body

  # before reading tmpFile, flush and close
  tmpFile.flushFile()  
  tmpFile.close()
  ident = readFile(tmpFileName)
  # Restore stdout
  discard dup2(stdoutDupfd, stdoutFileno)
