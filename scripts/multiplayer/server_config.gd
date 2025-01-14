extends Node

const API_ENDPOINT = "https://49g62vkb2l.execute-api.ap-south-1.amazonaws.com/prod"
const LOCAL_MODE = "local"
const AWS_MODE = "aws"

var server_mode = LOCAL_MODE
var server_id: String
var instance_id: String
var public_hostname: String

func _ready():
	parse_launch_args()
	if server_mode == AWS_MODE:
		instance_id = get_ec2_instance_id()
		server_id = "server-" + str(Time.get_unix_time_from_system())
		public_hostname = get_ec2_public_hostname()


func parse_launch_args():
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--mode="):
			server_mode = arg.split("=")[1]


func get_ec2_instance_id() -> String:
	var output = []
	var exit_code = OS.execute("ec2-metadata", ["-i"], output)
	if exit_code == 0:
		var id_line = output[0].strip_edges()
		return id_line.split(": ")[1]
	printerr("Failed to get instance ID")
	return ""


func get_ec2_public_hostname() -> String:
	var output = []
	var exit_code = OS.execute("ec2-metadata", ["-p"], output)
	if exit_code == 0:
		var id_line = output[0].strip_edges()
		return id_line.split(": ")[1]
	printerr("Failed to get public hostname")
	return ""


func is_aws_mode() -> bool:
	return server_mode == AWS_MODE
