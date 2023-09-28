#!/bin/bash

echo 100 > /sys/kernel/debug/tegra_mce/rt_window_us
echo 20 > /sys/kernel/debug/tegra_mce/rt_fwd_progress_us
echo 0x7f > /sys/kernel/debug/tegra_mce/rt_safe_mask