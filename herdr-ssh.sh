# Sourced from exedev's .bashrc. Only the outer interactive SSH login launches Herdr.
if [[ $- == *i* ]] && shopt -q login_shell &&    [[ -n ${SSH_CONNECTION:-} && -n ${SSH_TTY:-} ]] &&    [[ -t 0 && -t 1 && ${TERM:-dumb} != dumb ]] &&    [[ ${HERDR_ENV:-} != 1 && -z ${HERDR_PANE_ID:-} ]] &&    [[ ${HERDR_AUTO_START:-1} != 0 ]]; then
    if command -v herdr >/dev/null 2>&1; then
        herdr
    fi
fi
