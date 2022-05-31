import Analyze
import sys
import os
from datetime import date

# Perform all analysis and store in output_directory
def main(company_abbrev, hashtag, output_directory, start, end):
    if not os.path.isdir(output_directory):
        os.mkdir(output_directory)

    df = Analyze.get_df(hashtag, company_abbrev, start, end)
    print(df)
    gct = Analyze.test_correlation(df)
    f_ = open('{}/Granger-Test.txt'.format(output_directory), 'w+')
    f_.write(str(gct))
    f_.close()
    Analyze.plot_correlation(df, hashtag, '{}/Time-Series-Plot.png'.format(output_directory))


if __name__ == '__main__':

    # takes arguments company abbreviation, hashtag, and output directory
    company_abbrev = sys.argv[1]
    hashtag = sys.argv[2]
    output_directory = sys.argv[3]

    main(company_abbrev, hashtag, output_directory, date(2021, 9, 3), date(2021, 9, 15))
