#!/bin/bash
/opt/hadoop/bin/yarn --daemon start nodemanager
tail -f /dev/null
