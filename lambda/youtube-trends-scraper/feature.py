from typing import List

UNSAFE_CHARS = ['"', "'", "\n", "\r", "\t", "\b", "\f", "\v"]


def prepare_feature(feature: str) -> str:
    """
    Clean and prepare the feature string
    Removes any character from the unsafe characters list and surrounds the whole item in quotes
    :param feature:
    :return str:
    """

    for char in UNSAFE_CHARS:
        feature = feature.replace(char, '')

    return feature


def prepare_tags(tags: List[str]) -> str:
    """
    Prepare the tags list
    Joins the tags list into a single string and surrounds the whole item in quotes
    :param tags:
    :return str:
    """

    return "|".join(tags)
