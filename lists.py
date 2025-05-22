from argparse import ArgumentParser

parser = ArgumentParser()

parser.add_argument("-i", "--add", type=str)
parser.add_argument("-RD", "--remove-duplicates",
                    action="store_true", default=False)

args = parser.parse_args()

_INDENT = " "*2*2


def whitespace_join(arr: list[str]):
    return "\n".join(arr)


def omit_ln(_tuple: list[tuple[int, str]]):
    """
    Filters out the line numbers invoked from `read_stripped`, thus only leaving the lines themselves
    """
    return [l for _, l in _tuple]


def read_stripped(file: str, strip_comments=True):
    """
    This reads the file and strips out any empty and comment lines with `#`

    Returns:
        A list of tuple with line number and the line itself for identifying duplicates
    """
    try:
        with open(file, "r") as f:
            file_contents = enumerate(f.readlines())

            if not strip_comments:
                return [(ln, line.strip()) for ln, line in file_contents]

            strip_comments = [(ln, line.strip())
                              if not (line.startswith("#") or line.strip() == "") else None
                              for ln, line in file_contents]

            return list(filter(None, strip_comments))

    except FileNotFoundError as e:
        raise e


def dnsmasq_fmt(*domains: tuple[str]):
    domain_list = [f"config domain\n{_INDENT}option name '{domain}'\n{_INDENT}option ip '0.0.0.0'\n"
                   for domain in domains]

    return whitespace_join(domain_list)


def check_dups(arr: list[tuple[int, str]]):
    deduped_set: set[str] = set()
    duplicates_list: list[tuple[int, str]] = []

    for ln, item in arr:
        if item in deduped_set:
            duplicates_list.append((ln, item))
        else:
            deduped_set.add(item)

    len_dups = len(duplicates_list)

    if len_dups == 0:
        print("No duplicates are found")
        return arr

    print("Found {} duplicate(s)\n\n{}\n".format(
        len_dups,
        whitespace_join([f"{_INDENT} ln: {ln} - {dl}" for ln, dl in duplicates_list])  # noqa
    ))

    return list(deduped_set)


def main():
    hosts_record = read_stripped("hosts")
    dnsmasq_record = read_stripped("dnsmasq")
    pihole_record = read_stripped("PiHole", False)

    if args.remove_duplicates:
        print("In hosts:")
        check_dups(hosts_record)

        print("In PiHole:")
        check_dups(pihole_record)


if __name__ == "__main__":
    main()
