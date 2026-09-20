import pandas as pd

files = ["BMX_L", "DEMO_L", "PAQ_L"]

for file in files:
    df = pd.read_sas(f"{file}.xpt", format="xport")
    df.to_csv(f"{file}.csv", index=False)
