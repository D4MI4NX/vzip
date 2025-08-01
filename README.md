## Description

`zip` is a WIP [V](https://vlang.io/) module for creating ZIP archives.

## Example

```v
module main

import os
import time
import zip

fn main() {
	mut z := zip.Zip.new()

	// Add local files
	z.add_file('/home/user/Downloads', 'file.txt') or { panic(err) }

	z.add_file('/home/user/Pictures', 'cats/cat1.png') or { panic(err) }

	// Add entries manually
	z.files << zip.File{
		file_name: 'hello.txt',
		content: 'Hello, World!'.bytes(),
		mod_time: time.now()
	}

	zip_data := z.create()

	/*
	ZIP's contents:
	  - file.txt
	  - cats/cat1.png
	  - hello.txt
	*/

	os.write_bytes('output.zip', zip_data) or { panic(err) }
}
```

# Progress status
- Supports creating basic ZIP archives (without any options)

> [!WARNING]
> Do not use in production (yet)