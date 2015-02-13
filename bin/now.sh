now() {
      echo $(date "+%Y-%m-%d %H:%M:%S") - "$@" >> $HOME/.now
    }