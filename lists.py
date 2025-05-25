import sys
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-a", "--add",
                    type=str, nargs="+", metavar="records",
                    help="add an IP or domain name, will throw a warning if a domain/IP is already defined")

parser.add_argument("-c", "-check", "--check-duplicates",
                    action="store_true",
                    help="checks for duplicates and prints them to the console")

parser.add_argument("-rd", "--remove-duplicates",
                    action="store_true",
                    help="checks and removes any duplicates")


args = parser.parse_args()

_INDENT = " "*4


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


def check_dups(file_str: str, input_list: list[tuple[int, str]]) -> tuple[list[str], list[str]]:
    deduped_set: set[str] = set()
    duplicates_list: list[tuple[int, str]] = []

    clean_list = omit_ln(input_list)

    for ln, item in input_list:
        if item in deduped_set:
            duplicates_list.append((ln, item))
        else:
            deduped_set.add(item)

    len_dups = len(duplicates_list)

    if len_dups == 0:
        print("From {}: no duplicates are found".format(file_str))
        
        return clean_list, []

    print("From {}: found {} duplicate(s)\n\n{}\n".format(
        file_str,
        len_dups,
        whitespace_join([f"{_INDENT} ln {ln} | {dl}" for ln, dl in duplicates_list])  # noqa
    ))

    clean_list = list(deduped_set)

    return clean_list, omit_ln(duplicates_list)


def main():
    # We check for any duplicates so the script can return a proper exit status
    _root_dup_check = []

    included_files = [
        ("hosts", True),
        ("dnsmasq", True),
        ("pihole.txt", False)
    ]

    if args.remove_duplicates or args.check_duplicates:
        for file, strip_comments in included_files:
            domain_list = read_stripped(file, strip_comments=strip_comments)

            # dnsmasq needs to be parsed first for it to check any duplicates
            # then we format it back
            if file == "dnsmasq":
                continue

            clean_list, dup_list = check_dups(file, domain_list)
            _root_dup_check.append((file, dup_list))

        has_duplicates_found = any(v for _, v in _root_dup_check)
        dup_length = len([fv for _, v in _root_dup_check for fv in v])

        print(dup_length)

        if has_duplicates_found:
            print(f"Script has found duplicates: {dup_length}", "\n")
            sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(2)
    else:
        main()
