module zip

import encoding.binary
import hash.crc32
import os
import time

pub struct File {
	signature u32 = 0x504b0304
pub mut:
	version     u16 = 10
	flags       u16
	compression CompressionOptions
	mod_time    time.Time
	file_name   string @[required]
	extra_field map[u16]u16
	content     []u8
}

fn (f File) encode() []u8 {
	mut data := []u8{}

	// Signature
	data << binary.big_endian_get_u32(f.signature)

	// Version
	data << binary.little_endian_get_u16(f.version)

	// Flags
	data << binary.big_endian_get_u16(f.flags)

	// Compression
	data << binary.big_endian_get_u16(u16(f.compression))

	// Mod time
	data << binary.little_endian_get_u16(time_to_dos_format(f.mod_time))

	// Mod date
	data << binary.little_endian_get_u16(date_to_dos_format(f.mod_time))

	// Crc32 checksum
	data << binary.little_endian_get_u32(crc32.sum(f.content))

	// Compressed size
	data << binary.little_endian_get_u32(u32(f.content.len))

	// Uncompressed size
	data << binary.little_endian_get_u32(u32(f.content.len))

	// File name length
	data << binary.little_endian_get_u16(u16(f.file_name.len))

	// Extra field length
	data << binary.big_endian_get_u16(u16(f.extra_field.len) * 4)

	// File name
	data << os.to_slash(f.file_name).bytes()

	// Extra field
	for k, v in f.extra_field {
		data << binary.big_endian_get_u16(k)
		data << binary.big_endian_get_u16(v)
	}

	// Content
	data << f.content

	return data
}

struct FileHeader {
	signature                    u32 = 0x02014b50
	version_made_by              u16 = 10
	version_needed_to_extract    u16 = 10
	flags                        u16
	compression                  CompressionOptions
	last_mod_file_time           time.Time @[required]
	crc32_sum                    u32       @[required]
	compressed_size              u32       @[required]
	uncompressed_size            u32       @[required]
	filename                     string    @[required]
	extra_field                  map[u16]u16
	file_comment                 string
	disk_number_start            u16
	internal_file_attributes     u16
	external_file_attributes     u32
	relative_local_header_offset u32 @[required]
}

fn (fh FileHeader) encode() []u8 {
	mut data := []u8{}

	// Signature
	data << binary.little_endian_get_u32(fh.signature)

	// Version made by
	data << binary.little_endian_get_u16(fh.version_made_by)

	// Version needed to extract
	data << binary.little_endian_get_u16(fh.version_needed_to_extract)

	// Flags
	data << binary.big_endian_get_u16(fh.flags)

	// Compression method
	data << binary.big_endian_get_u16(u16(fh.compression))

	// Last mod file time
	data << binary.little_endian_get_u16(time_to_dos_format(fh.last_mod_file_time))

	// Last mod file date
	data << binary.little_endian_get_u16(date_to_dos_format(fh.last_mod_file_time))

	// Crc32
	data << binary.little_endian_get_u32(fh.crc32_sum)

	// Compressed size
	data << binary.little_endian_get_u32(fh.compressed_size)

	// Uncompressed size
	data << binary.little_endian_get_u32(fh.uncompressed_size)

	// Filename length
	data << binary.little_endian_get_u16(u16(fh.filename.len))

	// Extra field length
	data << binary.big_endian_get_u16(u16(fh.extra_field.len) * 4)

	// File comment length
	data << binary.big_endian_get_u16(u16(fh.file_comment.len))

	// Disk number start
	data << binary.big_endian_get_u16(fh.disk_number_start)

	// Internal file attributes
	data << binary.big_endian_get_u16(fh.internal_file_attributes)

	// External file attributes
	data << binary.big_endian_get_u32(fh.external_file_attributes)

	// Relative offset of local header
	data << binary.little_endian_get_u32(fh.relative_local_header_offset)

	// Filename
	data << os.to_slash(fh.filename).bytes()

	// Extra field
	for k, v in fh.extra_field {
		data << binary.big_endian_get_u16(k)
		data << binary.big_endian_get_u16(v)
	}

	// File comment
	data << fh.file_comment.bytes()

	return data
}

struct CentralDirectoryEnd {
	signature                                   u32 = 0x06054b50
	disk_number                                 u16
	disk_number_central_directory               u16
	disk_number_central_directory_total_entries u16 @[required]
	central_directory_total_entries             u16 @[required]
	central_directory_size                      u32 @[required]
	disk_number_central_directory_offset        u32 @[required]
	zipfile_comment                             string
}

fn (cde CentralDirectoryEnd) encode() []u8 {
	mut data := []u8{}

	// Signature
	data << binary.little_endian_get_u32(cde.signature)

	// Disk number
	data << binary.big_endian_get_u16(cde.disk_number)

	// Disk number central directory
	data << binary.big_endian_get_u16(cde.disk_number_central_directory)

	// Disk number central directory total entries
	data << binary.little_endian_get_u16(cde.disk_number_central_directory_total_entries)

	// Central directory total entries
	data << binary.little_endian_get_u16(cde.central_directory_total_entries)

	// Central directory size
	data << binary.little_endian_get_u32(cde.central_directory_size)

	// Disk number central directory offset
	data << binary.little_endian_get_u32(cde.disk_number_central_directory_offset)

	// Zipfile comment length
	data << binary.big_endian_get_u16(u16(cde.zipfile_comment.len))

	// Zipfile comment
	data << cde.zipfile_comment.bytes()

	return data
}

enum Flags as u16 {
	none
}

pub enum CompressionOptions as u16 {
	none
}

pub struct Zip {
pub mut:
	files []File
}

// new creates a new Zip object
pub fn Zip.new() Zip {
	return Zip{}
}

// add_file adds a local file to the Zip object, storing it with a specified relative path.
//
// ### Parameters
// - `root_path`: The base directory from which the relative path is derived.
// - `relative_path`: The path of the file as it will appear inside the ZIP archive.
//
// Example: Zip.add_file('/tmp/example', 'subdir/file.txt')! // '/tmp/example/subdir/file.txt' stored as 'subdir/file.txt' in ZIP archive
pub fn (mut z Zip) add_file(root_path string, relative_path string) ! {
	mut f := File{
		file_name: relative_path
	}

	path := os.join_path_single(root_path, relative_path)

	content := os.read_bytes(path)!
	mod_time := os.file_last_mod_unix(path)

	f.content = content
	f.mod_time = time.unix(mod_time).local()

	z.files << f
}

// create creates and returns the complete data of the ZIP archive
// Example: os.write_bytes('output.zip', Zip.create()) // Write the ZIP to 'output.zip'
pub fn (z Zip) create() []u8 {
	mut data := []u8{}

	mut local_header_offsets := []u32{}

	// Local file header
	for f in z.files {
		local_header_offsets << u32(data.len)

		data << f.encode()
	}

	// File header
	cd_start := data.len

	for i, f in z.files {
		fh := FileHeader{
			last_mod_file_time:           f.mod_time
			crc32_sum:                    crc32.sum(f.content)
			compressed_size:              u32(f.content.len)
			uncompressed_size:            u32(f.content.len)
			filename:                     f.file_name
			relative_local_header_offset: local_header_offsets[i]
		}

		data << fh.encode()
	}

	// Central directory end
	cde := CentralDirectoryEnd{
		disk_number_central_directory_total_entries: u16(z.files.len)
		central_directory_total_entries:             u16(z.files.len)
		central_directory_size:                      u32(data.len - cd_start)
		disk_number_central_directory_offset:        u32(cd_start)
	}

	data << cde.encode()

	return data
}
