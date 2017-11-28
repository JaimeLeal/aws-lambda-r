import os
import imp
import sys
os.environ["R_HOME"] = os.getcwd()
os.environ["R_LIBS"] = os.path.join(os.getcwd(), 'libraries')
sys.modules["sqlite"] = imp.new_module("sqlite")
sys.modules["sqlite3.dbapi2"] = imp.new_module("sqlite.dbapi2")
import rpy2
import ctypes
import rpy2.robjects as robjects
import json


for file in os.listdir('lib/external'):
	file_name='lib/external/' + file
	ctypes.cdll.LoadLibrary(os.path.join(os.getcwd(), file_name))


# source R file
# this R file might load libraries and source other files
robjects.r['source']('example.R')

# exposing R entry point to python
aws_lambda_r = robjects.globalenv['aws_lambda_r']


def handler_post(event, context):

	input_json = json.dumps(event)
	output_json = aws_lambda_r(input_json)
	return output_json

    
# print(handler_post({"request_id": "Hey"}, None))
