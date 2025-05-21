from argparse import ArgumentParser

parser = ArgumentParser()

parser.add_argument("-i", "--add", type=str)
parser.add_argument("-RD", "--remove-duplicates",
                    action="store_true", default=False)

args = parser.parse_args()

_INDENT = " "*2*2


def whitespace_join(arr: list[str]):
    return "\n".join(arr)


def read_stripped(file: str, strip_lines=True):
    """
    This reads the file and strips out any empty and comment lines with `#`
    """
    try:
        with open(file, "r") as f:
            file_contents = f.readlines()

            if not strip_lines:
                return file_contents

            strip_comments = [l.strip()
                              if not l.startswith("#") else None
                              for l in file_contents]

            return list(filter(None, strip_comments))

    except FileNotFoundError as e:
        raise e


def dnsmasq_fmt(*domains):

    domain_list = [f"config domain\n{_INDENT}option name '{domain}'\n{_INDENT}option ip '0.0.0.0'\n"
                   for domain in domains]

    return whitespace_join(domain_list)


def check_dups(arr: list[str]):
    deduped_set: set[str] = set()
    duplicates: list[str] = []

    for item in arr:
        if item in deduped_set:
            duplicates.append(item)
        else:
            deduped_set.add(item)

    len_dups = len(duplicates)

    if len_dups == 0:
        print("There are no duplicates")
        return arr

    print("Found {} duplicate(s)\n\n{}\n".format(
        len_dups,
        whitespace_join([f"{_INDENT}- {d}" for d in duplicates])
    ))

    return list(deduped_set)


def main():
    hosts_record = read_stripped("hosts")
    dnsmasq_record = read_stripped("dnsmasq")
    pihole_record = read_stripped("PiHole", False)

    if args.remove_duplicates:
        check_dups(hosts_record)


if __name__ == "__main__":
    main()
