# KDE session/power. The KDE versions close apps cleanly and save the session.
abbr -a sleepnow 'systemctl suspend'
abbr -a logout 'qdbus6 org.kde.Shutdown /Shutdown logout'
abbr -a shutdown 'qdbus6 org.kde.Shutdown /Shutdown logoutAndShutdown'
abbr -a restart 'qdbus6 org.kde.Shutdown /Shutdown logoutAndReboot'
