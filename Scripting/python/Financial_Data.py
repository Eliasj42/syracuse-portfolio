import numpy as np
import pandas as pd
import yfinance as yf
from datetime import datetime, timedelta, date

# Pull data from yahoo finance
def retrieve_data(company_abbrev, start, end):
    df = yf.download(company_abbrev, start.strftime('%Y-%m-%d'), end.strftime('%Y-%m-%d'))
    df = df.resample('D').ffill().reset_index() # fill in weekend and holiday data
    return df


