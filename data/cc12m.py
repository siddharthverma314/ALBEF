from __future__ import annotations
from typing import Optional, NamedTuple
from pathlib import Path
import argparse
import zlib
from tqdm.contrib.concurrent import process_map
import json
from functools import partial
import pandas as pd


def crc32(s: str):
    return zlib.crc32(s.encode("utf-8")) & 0xFFFFFFFF


class DataPoint(NamedTuple):
    image: str
    caption: str

    @staticmethod
    def from_tsv(index: int, imgdir: Path) -> Optional[DataPoint]:
        global df
        row = df.iloc[index]
        path = imgdir / f"{row.i}_{crc32(row.url)}"
        if not path.exists():
            return None
        return DataPoint(image=str(path), caption=row.caption)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--tsv")
    parser.add_argument("--imgdir")
    parser.add_argument("--out")
    args = parser.parse_args()

    df = (
        pd.read_csv(args.tsv, sep="\t", names=["caption", "url"])
        .reset_index()
        .rename(columns={"index": "i"})
    )
    data = process_map(
        partial(DataPoint.from_tsv, imgdir=Path(args.imgdir)),
        range(len(df)),
        chunksize=32,
    )
    data = [x._asdict() for x in data if x is not None]
    with open(args.out, "w") as f:
        json.dump(data, f)
