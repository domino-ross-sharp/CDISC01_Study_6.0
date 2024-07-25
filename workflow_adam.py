import os
from flytekit import workflow
from flytekit.types.file import FlyteFile
from utils.adam import create_adam_data
from utils.tfl import create_tfl_report
from typing import TypeVar, NamedTuple

#adam_outputs = NamedTuple("adam_outputs", adsl=FlyteFile[TypeVar("sas7bdat")])

@workflow
def ADaM(sdtm_data_path: str):
    """
    This script mocks a sample clinical trial using Domino Flows. 

    The input to this flow is the path  to your SDTM data. You can point this to either your SDTM-BLIND dataset or your SDTM-UNBLIND dataset. The output to this flow are a series of TFL reports.

    To the run the workflow remotely, execute the following code in your terminal:
    
    pyflyte run --remote workflow_adam.py ADaM --sdtm_data_path /mnt/imported/data/SDTMBLIND/JUL162024

    :param sdtm_data_path: The root directory of your SDTM dataset
    :return: A list of PDF files containing the TFL reports
    """
    # Create task that generates ADSL dataset. This will run a unique Domino job and return its outputs.
    adsl = create_adam_data(
        name="ADSL", 
        command="prod/adam_flows/ADSL.sas",
        environment="SAS Analytics Pro",
        hardware_tier= "Small", # Optional parameter. If not set, then the default for the project will be used.
        sdtm_data_path=sdtm_data_path # Note this this is simply the input value taken in from the command line argument
    )
  