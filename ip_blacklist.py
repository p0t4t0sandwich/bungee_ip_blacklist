#!/bin/python3
#--------------------------------------------------------------------
# Project: IP Blacklister
# Purpose: To grep logs and mitigate ongoing ddos attacks.
# Author: Dylan Sperrer (p0t4t0sandwich|ThePotatoKing)
# Date: 05JUNE2022
# Updated: 23AUGUST2022 by p0t4t0sandwich
#           - Revamped the whole process using Polars
#--------------------------------------------------------------------

# Blacklist Generation
import polars as pl
import gzip, os

# Discord Bot
import discord
from discord.ext import commands

class Blacklist():
    def __init__(self, blacklist_file):
        self.blacklist_file = blacklist_file

    def generate_blacklist(self, directory):
        #ip_regex = r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
        ip_regex = r'([0-9]{1,3}[\.]){3}[0-9]{1,3}'

        main_search = "Query - Incorrect magic!"

        filter_invalid_ips = ["255.255.255.255", "0.0.0.0", "8.8.8.8", "1.1.1.1", "1.0.0.1", "127.0.0.1"]

        dfs = []

        for i in os.listdir(directory):
            filename = os.path.join(directory, i)
            if os.path.isfile(filename):
                try:
                    if ".gz" in filename:
                        data = gzip.open(filename,"rb")
                    else:
                        data = open(filename, "r")

                    dataset = pl.read_csv(data, header=None)

                    if len(dataset.columns) > 1:
                        print(f"Abnormal dataset: {filename}")
                    else:
                        renamed = dataset.rename({dataset.columns[0]:"ip_data"})
                        dfs.append(renamed)
                except:
                    print(f"Error reading:    {filename}")

        all_df = pl.concat(dfs, rechunk=True)
        self.log_length = len(all_df)

        blacklist = (
            all_df.lazy()
            .filter(pl.col("ip_data").cast(pl.Utf8).str.contains(main_search))
            .with_column(pl.col("ip_data").cast(pl.Utf8).str.extract(ip_regex, 0))
            .unique()
            .filter(~pl.col("ip_data").cast(pl.Utf8).str.starts_with("0"))
            .filter(~pl.col("ip_data").is_in(filter_invalid_ips))
            .sort("ip_data")
        ).collect()

        blacklist.write_csv(self.blacklist_file,has_header=True)
        return f"{len(blacklist)} IP addresses have been added to the blacklist from {self.log_length} lines of logs!"

    def generate_blocklists(self, directory):
        # Check to see if the blacklist file exists
        if not os.path.isfile(self.blacklist_file):
            return "Please generate a blacklist"

        data = open(self.blacklist_file, "r")
        blacklist = pl.read_csv(data, header="ip_data")

        formatted = blacklist

        if not os.path.exists(directory): os.mkdir(directory)

        blocklist_ammount = len(formatted)//(256**2)+1

        for i in range(blocklist_ammount):
            formatted_file = (
                formatted.lazy()
                .head(256**2)
                .select(pl.format("add blocklist_" + str(i) + " {} -exist", pl.col("ip_data")).alias("ip_data"),)

            ).collect()
            formatted_file.write_csv(f"{directory}/blocklist_{i}",has_header=False)
            formatted_temp = (
                formatted.lazy()
                .filter(~pl.col("ip_data").is_in(formatted_file["ip_data"]))
            )
            formatted = formatted_temp.collect()

        return f"{blocklist_ammount - 1} blocklists have been generated!"

if __name__ == "__main__":
    blacklist = Blacklist("ip_blacklist.txt")
    
    log_directory = "./logs/"
    print(blacklist.generate_blacklist(log_directory))
    
    blocklist_directory = "./blocklists"
    print(blacklist.generate_blocklists(blocklist_directory))
