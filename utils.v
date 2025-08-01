module zip

import time

fn time_to_dos_format(t time.Time) u16 {
	mut result := u16(0)

	// Seconds
	result |= u16(t.second / 2)

	// Minutes
	result |= u16(t.minute) << 5

	// Hours
	result |= u16(t.hour) << 11

	return u16(result)
}

fn date_to_dos_format(t time.Time) u16 {
	mut result := u16(0)

	// Day
	result |= u16(t.day)

	// Month
	result |= u16(t.month) << 5

	// Year
	result |= u16(t.year - 1980) << 9

	return result
}
