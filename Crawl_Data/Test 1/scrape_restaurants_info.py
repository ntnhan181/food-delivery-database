import time
import os
import json
import warnings
import random
import pandas as pd
import numpy as np
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium import webdriver
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.chrome.options import Options

warnings.filterwarnings("ignore")


def driver_operation(url, size):
    # options = webdriver.ChromeOptions()  # I would also suggest to use this instead of Options()
    # options.add_argument("--headless")
    # options.add_argument("--enable-javascript")  # To be on the safe side, although it seems to be enabled by default

    # options = webdriver.ChromeOptions()
    # options.add_experimental_option('excludeSwitches', ['enable-logging'])
    # driver = webdriver.Chrome(options=options)

    time.sleep(1)
    options = webdriver.ChromeOptions()
    options.add_experimental_option('excludeSwitches', ['enable-logging'])
    driver = webdriver.Chrome(executable_path="chromedriver_win32/chromedriver.exe", options=options)
    driver.maximize_window()
    driver.set_window_size(1920, 1080)
    driver.get(url)


    # options = Options()
    # options.add_argument("headless")
    # options.add_experimental_option("excludeSwitches", ["enable-logging"])
    
    driver.find_element_by_xpath(
        "/html/body/div[1]/div[1]/div/div[5]/div/div/div[2]/div[2]/button"
    ).click()
    time.sleep(1)

    for i in range(0, size + 1):
        driver.execute_script(
            "window.scrollTo({start}*document.body.scrollHeight/{r}, {end}*document.body.scrollHeight/{r})".format(
                start=i, end=i + 1, r=size
            )
        )
        time.sleep(2)

    return driver


def scrape_restaurant_info(driver, url):
    small_display = "/html/body/div[1]/div[1]/div/main/div[5]/ul"
    large_display = "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul"
    large_v2_display = "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul"

    # lst_check = [check_exists_by_xpath(small_display, driver), check_exists_by_xpath(large_display, driver), check_exists_by_xpath(large_v2_display, driver)]

    try:
        df_restaurant = scrape_restaurant_small_display(driver)
    except:
        try:
            df_restaurant = scrape_restaurant_large_display(driver)
        except:
            try:
                df_restaurant = scrape_restaurant_large_display_v2(driver)
            except Exception:
                print("Skip " + url)
                with open("restaurant_fail.txt", "a") as f:
                    f.write(url + "\n")
                driver.close()
                return None

    # try:
    #         if lst_check[0] is True:
    #                 df_restaurant = scrape_restaurant_small_display(driver)
    #                 print('small')
    #         elif lst_check[1] is True and lst_check[2] is False:
    #                 df_restaurant = scrape_restaurant_large_display(driver)
    #                 print('large')
    #         elif lst_check[2] is True and lst_check[1] is False:
    #                 df_restaurant = scrape_restaurant_large_display_v2(driver)
    #                 print('large v2')
    #         elif lst_check[1] is True and lst_check[2] is True:
    #                 df_restaurant = scrape_restaurant_large_display(driver)

    # except Exception:
    #         print('Skip ' + url)
    #         with open('restaurant_fail.txt', 'a') as f:
    #                 f.write(url+'\n')
    #         driver.close()
    #         return None

    driver.close()
    print(url+' scrape successfully')
    return df_restaurant


def scrape_restaurant_small_display(driver):
    small_display = "/html/body/div[1]/div[1]/div/main/div[5]/ul"
    df_restaurant = pd.DataFrame(
        columns=[
            "title",
            "detail",
            "rating",
            "num_review",
            "menu_category",
            "name",
            "price",
            "description",
            "status",
            "img_url",
        ]
    )

    # ===== Header details =====
    title = ""
    detail = ""
    rating = ""
    num = ""

    try:
        detail = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[4]/div/div[1]/div"
        ).text

    except:
        detail = ""

    try:
        rating = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/div[1]/div[1]"
        ).text
    except:
        rating = ""

    try:
        num = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/div[1]/div[3]"
        ).text
    except:
        num = ""

    try:
        title = (
            driver.find_element_by_xpath(
                "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/h1"
            ).text,
        )

    except:
        title = ""

    # menu
    list_item_element = driver.find_element_by_xpath(
        small_display
    ).find_element_by_tag_name("li")
    class_name = list_item_element.get_attribute("class").replace(" ", ".")
    menu = driver.find_element_by_xpath(small_display).find_elements_by_class_name(
        class_name
    )

    for x in range(1, len(menu) + 1):
        cat_pos = "/html/body/div[1]/div[1]/div/main/div[5]/ul/li[" + str(x) + "]/h2"
        category = driver.find_element_by_xpath(cat_pos).text

        # restaurant['menu'].append({
        #         category: []
        # })
        section = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[5]/ul/li[" + str(x) + "]/ul"
        ).find_elements_by_tag_name("li")

        for y in range(1, len(section) + 1):

            # Get Product Name
            try:
                name = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div/div[1]/div[1]/h4/div"
                    ).text
                )
            except:
                name = ""

            ## Get Product Description
            try:

                description = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div/div[1]/div[2]/div"
                    ).text
                )

            except:
                description = ""

            # Get Product Price
            try:
                price = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div/div[1]/div[3]/div"
                    ).text
                )

                status = "In stock"
                if price == description:
                    description = ""

                if "Sold" in price:
                    status = "Sold out"
                    price = "$" + price.split("$", 1)[1]
                else:
                    status = "In stock"
            except:

                if "$" in description:
                    price = description
                    description = ""
                else:
                    price = ""
                    status = "In stock"

            # Get Image URL

            try:
                img_url = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div/div[2]/div/picture/img"
                    ).get_attribute("src")
                )

            except:
                img_url = ""

            try:
                df_restaurant = df_restaurant.append(
                    {
                        "title": title,
                        "detail": detail,
                        "rating": rating,
                        "num_review": num,
                        "menu_category": category,
                        "name": name,
                        "price": price,
                        "description": description,
                        "status": status,
                        "img_url": img_url,
                    },
                    ignore_index=True,
                )
            except:
                df_restaurant = df_restaurant.append(
                    {
                        "title": title,
                        "detail": detail,
                        "rating": rating,
                        "num_review": num,
                        "menu_category": category,
                        "name": name,
                        "price": price,
                        "description": description,
                        "img_url": img_url,
                    },
                    ignore_index=True,
                )

    return df_restaurant


def scrape_restaurant_large_display(driver):
    df_restaurant = pd.DataFrame(
        columns=[
            "title",
            "detail",
            "rating",
            "num_review",
            "menu_category",
            "name",
            "price",
            "description",
            "status",
            "img_url",
        ]
    )
    large_display = "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul"

    # ===== Header details =====
    title = ""
    detail = ""
    rating = ""
    num = ""

    try:
        detail = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[4]/div/div[1]/div"
        ).text

    except:
        detail = ""

    try:
        rating = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/div[1]/div[1]"
        ).text
    except:
        rating = ""

    try:
        num = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/div[1]/div[3]"
        ).text
    except:
        num = ""

    try:
        title = (
            driver.find_element_by_xpath(
                "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/h1"
            ).text,
        )

    except:
        title = ""

    # menu
    list_item_element = driver.find_element_by_xpath(
        large_display
    ).find_element_by_tag_name("li")
    class_name = list_item_element.get_attribute("class").replace(" ", ".")
    menu = driver.find_element_by_xpath(large_display).find_elements_by_class_name(
        class_name
    )

    for x in range(1, len(menu) + 1):
        cat_pos = (
            "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul/li["
            + str(x)
            + "]/div[1]"
        )
        category = driver.find_element_by_xpath(cat_pos).text
        # restaurant['menu'].append({
        #         category: []
        # })

        section = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul/li["
            + str(x)
            + "]/ul"
        ).find_elements_by_tag_name("li")

        for y in range(1, len(section) + 1):

            # Get Product Name
            try:
                name = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[2]/div[1]/span"
                    ).text
                )
            except:
                name = ""

            ## Get Product Description
            try:

                description = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[2]/div[1]/span"
                    ).text
                )

            except:
                description = ""

            # Get Product Price
            try:

                price = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[2]/div[2]/span"
                    ).text
                )

                if price == description:
                    description = ""

                if "Sold" in price:
                    status = "Sold out"
                    price = "$" + price.split("$", 1)[1]
                else:
                    status = "In stock"
            except:

                if "$" in description:
                    price = description
                    description = ""
                else:
                    price = ""

            # Get Image URL
            try:
                img_url = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div[2]/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[1]/div/picture/img"
                    ).get_attribute("src")
                )

            except:
                img_url = ""

            try:
                df_restaurant = df_restaurant.append(
                    {
                        "title": title,
                        "detail": detail,
                        "rating": rating,
                        "num_review": num,
                        "menu_category": category,
                        "name": name,
                        "price": price,
                        "description": description,
                        "status": status,
                        "img_url": img_url,
                    },
                    ignore_index=True,
                )
            except:
                df_restaurant = df_restaurant.append(
                    {
                        "title": title,
                        "detail": detail,
                        "rating": rating,
                        "num_review": num,
                        "menu_category": category,
                        "name": name,
                        "price": price,
                        "description": description,
                        "img_url": img_url,
                    },
                    ignore_index=True,
                )

    return df_restaurant


def scrape_restaurant_large_display_v2(driver):
    df_restaurant = pd.DataFrame(
        columns=[
            "title",
            "detail",
            "rating",
            "num_review",
            "menu_category",
            "name",
            "price",
            "description",
            "status",
            "img_url",
        ]
    )
    large_v2_display = "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul"

    # ===== Header details =====
    title = ""
    detail = ""
    rating = ""
    num = ""

    try:
        detail = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[4]/div/div[1]/div"
        ).text

    except:
        detail = ""

    try:
        rating = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/div[1]/div[1]"
        ).text
    except:
        rating = ""

    try:
        num = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/div[1]/div[3]"
        ).text
    except:
        num = ""

    try:
        title = (
            driver.find_element_by_xpath(
                "/html/body/div[1]/div[1]/div/main/div[3]/div/div[2]/div[3]/div[1]/div[2]/div[2]/h1"
            ).text,
        )

    except:
        title = ""

    # menu
    list_item_element = driver.find_element_by_xpath(
        large_v2_display
    ).find_element_by_tag_name("li")
    class_name = list_item_element.get_attribute("class").replace(" ", ".")
    menu = driver.find_element_by_xpath(large_v2_display).find_elements_by_class_name(
        class_name
    )

    for x in range(1, len(menu) + 1):
        cat_pos = (
            "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul/li["
            + str(x)
            + "]/div[1]"
        )
        category = driver.find_element_by_xpath(cat_pos).text
        # restaurant['menu'].append({
        #         category: []
        # })
        section = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul/li["
            + str(x)
            + "]/ul"
        ).find_elements_by_tag_name("li")

        for y in range(1, len(section) + 1):

            # Get Product Name
            try:
                name = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[2]/div[1]/span"
                    ).text
                )
            except:
                name = ""

            ## Get Product Description
            try:

                description = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[2]/div[1]/span"
                    ).text
                )

            except:
                description = ""

            # Get Product Price
            try:
                price = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[2]/div[2]/span"
                    ).text
                )

                if price == description:
                    description = ""

                if "Sold" in price:
                    status = "Sold out"
                    price = "$" + price.split("$", 1)[1]
                else:
                    status = "In stock"
            except:

                if "$" in description:
                    price = description
                    description = ""
                else:
                    price = ""

            # Get Image URL
            try:
                img_url = str(
                    driver.find_element_by_xpath(
                        "/html/body/div[1]/div[1]/div/main/div[5]/div/div[4]/ul/li["
                        + str(x)
                        + "]/ul/li["
                        + str(y)
                        + "]/div/div/div[1]/div/picture/img"
                    ).get_attribute("src")
                )

            except:
                img_url = ""

            try:
                df_restaurant = df_restaurant.append(
                    {
                        "title": title,
                        "detail": detail,
                        "rating": rating,
                        "num_review": num,
                        "menu_category": category,
                        "name": name,
                        "price": price,
                        "description": description,
                        "status": status,
                        "img_url": img_url,
                    },
                    ignore_index=True,
                )
            except:
                df_restaurant = df_restaurant.append(
                    {
                        "title": title,
                        "detail": detail,
                        "rating": rating,
                        "num_review": num,
                        "menu_category": category,
                        "name": name,
                        "price": price,
                        "description": description,
                        "img_url": img_url,
                    },
                    ignore_index=True,
                )

    return df_restaurant


def scroll_to_bottom(driver):

    old_position = 0
    new_position = None

    while new_position != old_position:
        # Get old scroll position
        old_position = driver.execute_script(
            (
                "return (window.pageYOffset !== undefined) ?"
                " window.pageYOffset : (document.documentElement ||"
                " document.body.parentNode || document.body);"
            )
        )
        # Sleep and Scroll
        time.sleep(1)
        driver.execute_script(
            (
                "var scrollingElement = (document.scrollingElement ||"
                " document.body);scrollingElement.scrollTop ="
                " scrollingElement.scrollHeight;"
            )
        )
        # Get new position
        new_position = driver.execute_script(
            (
                "return (window.pageYOffset !== undefined) ?"
                " window.pageYOffset : (document.documentElement ||"
                " document.body.parentNode || document.body);"
            )
        )


def scrape_restaurants(base_url, location, driver):

    cat = []
    try:
        temp_urls = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[2]/div[3]"
        ).find_elements_by_tag_name("a")
        for url in temp_urls:
            cat.append(url.get_attribute("href"))
    except:
        print("Skipped " + cat)

    with open("temp_urls.txt", "a") as f:
        cat_str = list(map(lambda x: str(x) + "\n", cat))
        for i in cat_str:
            f.write(i)

    lines_seen = set()  # holds lines already seen
    out_file = open(location + "_restaurant_urls.txt", "w+")
    for line in open("temp_urls.txt", "r"):
        if line not in lines_seen:  # not a duplicate
            out_file.write(line)
            lines_seen.add(line)
    out_file.close()
    os.remove("temp_urls.txt")

    with open(location + "_restaurant_urls.txt") as file:
        categories_lst = file.readlines()

    categories_lst = [str(i)[:-1] for i in categories_lst]

    driver = webdriver.Chrome(executable_path="chromedriver_win32/chromedriver.exe")
    driver.maximize_window()
    driver.set_window_size(1920, 1080)

    restaurant_arr = []
    for url in categories_lst:
        driver.get(url)
        restaurant_lst = driver.find_element_by_xpath(
            "/html/body/div[1]/div[1]/div/main/div[5]/div"
        ).find_elements_by_tag_name("a")
        for i in restaurant_lst:
            restaurant_arr.append(i.get_attribute("href"))

    with open("restaurant.txt", "a") as f:
        restaurant_str2 = list(map(lambda x: str(x) + "\n", restaurant_arr))
        for i in restaurant_str2:
            f.write(i)

    os.remove("temp_urls.txt")


def main(num):
    with open("restaurant.txt") as f:
        lst_urls = f.read().splitlines()

    df = pd.DataFrame(
        columns=[
            "title",
            "detail",
            "rating",
            "num_review",
            "menu_category",
            "name",
            "price",
            "description",
            "status",
            "img_url",
        ]
    )
    df.to_csv("data.csv", encoding="utf-8-sig", mode="w", index=False)
    lst_urls_test = random.sample(lst_urls, num)

    for url in lst_urls_test:
        driver = driver_operation(url, 14)
        df = scrape_restaurant_info(driver, url)
        if df is not None:
            df.to_csv(
                "data.csv", encoding="utf-8-sig", mode="a", header=False, index=False
            )
            df = df.iloc[0:0]
