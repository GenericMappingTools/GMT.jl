# Generated using Clang.jl wrap_c, version 0.0.0

Base.@kwdef mutable struct laszip_geokey
	key_id::UInt16 = UInt16(0)
	tiff_tag_location::UInt16 = UInt16(0)
	count::UInt16 = UInt16(0)
	value_offset::UInt16 = UInt16(0)
end

Base.@kwdef mutable struct laszip_vlr
	reserved::UInt16 = UInt16(0)
	user_id::NTuple{16,UInt8} = ntuple(i -> UInt8(0x0), 16)
	record_id::UInt16 = UInt16(0)
	record_length_after_header::UInt16 = UInt16(0)
	description::NTuple{32,UInt8} = ntuple(i -> UInt8(0x0), 32)
	data::Ptr{Cuchar} = pointer("")
end

Base.@kwdef mutable struct laszip_header
	file_source_ID::UInt16 = UInt16(0)
	global_encoding::UInt16 = UInt16(0)
	project_ID_GUID_data_1::UInt32 = UInt32(0)
	project_ID_GUID_data_2::UInt16 = UInt16(0)
	project_ID_GUID_data_3::UInt16 = UInt16(0)
	project_ID_GUID_data_4::NTuple{8,UInt8} = ntuple(i -> UInt8(20), 8)
	version_major::UInt8 = UInt8(1)
	version_minor::UInt8 = UInt8(2)
	system_identifier::NTuple{32,UInt8} = ntuple(i -> UInt8(20), 32)
	generating_software::NTuple{32,UInt8} = ntuple(i -> UInt8(20), 32)
	file_creation_day::UInt16 = UInt16((today() - Date(year(today()))).value)
	file_creation_year::UInt16 = UInt16(year(today()))
	header_size::UInt16 = UInt16(227)
	offset_to_point_data::UInt32 = UInt32(227)
	number_of_variable_length_records::UInt32 = UInt32(0)
	point_data_format::UInt8 = UInt8(0)
	point_data_record_length::UInt16 = UInt16(0)
	number_of_point_records::UInt32 = UInt32(0)
	number_of_points_by_return::NTuple{5,UInt32} = ntuple(i -> UInt32(0), 5)
	x_scale_factor::Float64 = 1.0
	y_scale_factor::Float64 = 1.0
	z_scale_factor::Float64 = 1.0
	x_offset::Float64 = 0.0
	y_offset::Float64 = 0.0
	z_offset::Float64 = 0.0
	max_x::Float64 = 0.0
	min_x::Float64 = 0.0
	max_y::Float64 = 0.0
	min_y::Float64 = 0.0
	max_z::Float64 = 0.0
	min_z::Float64 = 0.0
# LAS 1.3 and higher only
	start_of_waveform_data_packet_record::UInt64  = UInt64(0)

# LAS 1.4 and higher only
	start_of_first_extended_variable_length_record::UInt64 = UInt64(0)
	number_of_extended_variable_length_records::UInt32 = UInt32(0)
	extended_number_of_point_records::UInt64 = UInt64(0)
	extended_number_of_points_by_return::NTuple{15,UInt64} = ntuple(i -> UInt64(0), 15)

# optional
	user_data_in_header_size::UInt32 = UInt32(0)
	user_data_in_header::Ptr{UInt8} = pointer("")

# optional VLRs
	vlrs::Ptr{laszip_vlr} = pointer("")

# optional
	user_data_after_header_size::UInt32 = UInt32(0)
	user_data_after_header::Ptr{UInt8} = pointer("")
end

Base.@kwdef mutable struct laszip_point
    X::Int32 = Int32(0)
    Y::Int32 = Int32(0)
    Z::Int32 = Int32(0)
    intensity::UInt16 = UInt16(0)
	return_number::UInt8 = UInt8(0)
	number_of_returns::UInt8 = UInt8(0)
	scan_direction_flag::UInt8 = UInt8(0)
	edge_of_flight_line::UInt8 = UInt8(0)
	classification::UInt8 = UInt8(0)
	synthetic_flag::UInt8 = UInt8(0)
	keypoint_flag::UInt8 = UInt8(0)
	withheld_flag::UInt8 = UInt8(0)
	scan_angle_rank::Int8 = Int8(0)
	user_data::UInt8 = UInt8(0)
	point_source_ID::UInt16 = UInt16(0)
# LAS 1.4 only
	extended_scan_angle::Int16 = Int16(0)
	extended_point_type::UInt8 = UInt8(0)
	extended_scanner_channel::UInt8 = UInt8(0)
	extended_classification_flags::UInt8 = UInt8(0)
	extended_classification::UInt8 = UInt8(0)
	extended_return_number::UInt8 = UInt8(0)
	extended_number_of_returns::UInt8 = UInt8(0)
# for 8 byte alignment of the GPS time
	#dummy::NTuple{7,UInt8} = ntuple(i -> UInt8(0), 7)
	dummy::NTuple{3,UInt16} = ntuple(i -> UInt8(0), 3)
	rgb::NTuple{4,UInt16} = ntuple(i -> UInt16(0), 4)
	gps_time::Float64 = Float64(0.0)
	#rgb::NTuple{4,UInt16} = ntuple(i -> UInt16(0), 4)
	wave_packet::NTuple{29,UInt8} = ntuple(i -> UInt8(0), 29)
	num_extra_bytes::Int32 = Int32(0)
	extra_bytes::Ptr{UInt8} = pointer("")
end
