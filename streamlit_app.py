# Welcome to Streamlit in Snowflake!

# Import necessary libraries
# streamlit is used for creating the web app interface.
import streamlit as st
# pandas is used for data manipulation and analysis.
import pandas as pd
# altair is used for creating interactive data visualizations.
import altair as alt
# snowflake.snowpark.context is used to connect to Snowflake and get the active session.
from snowflake.snowpark.context import get_active_session

# --- App Setup and Data Loading ---

# Get the active Snowpark session to interact with Snowflake.
session = get_active_session()

# Set the title of the Streamlit application, which appears at the top of the page.
st.title("Menu Item Sales in Japan for February 2022")

st.write('---') # Creates a divider line

# Define a function to load data from Snowflake.
# @st.cache_data is a Streamlit decorator that caches the output of this function.
# This means the data will only be fetched from Snowflake once, improving performance
# on subsequent runs or when a user interacts with widgets.
@st.cache_data()
def load_data():
    """
    Connects to a Snowflake table, fetches the data, and returns it as a Pandas DataFrame.
    """
    # Use the active session to reference a table in Snowflake and convert it to a Pandas DataFrame.
    # Note: The original variable name 'germany_sales_df' was potentially confusing given the context.

    japan_sales_df = session.table("tb_101.analytics.japan_menu_item_sales_feb_2022").to_pandas()
    return japan_sales_df

# Call the function to load the data. Thanks to caching, this will be fast after the first run. 
japan_sales = load_data()


# --- User Interaction with Widgets ---

# Get a unique list of menu item names from the DataFrame to populate the dropdown.
menu_item_names = japan_sales['MENU_ITEM_NAME'].unique().tolist()

# Create a dropdown menu (selectbox) in the Streamlit sidebar or main page.
# The user's selection will be stored in the 'selected_menu_item' variable.
selected_menu_item = st.selectbox("Select a menu item", options=menu_item_names)


# --- Data Setup ---

# Filter the main DataFrame to include only the rows that match the user's selected menu item.
menu_item_sales = japan_sales[japan_sales['MENU_ITEM_NAME'] == selected_menu_item]

# Group the filtered data by 'DATE' and calculate the sum of 'ORDER_TOTAL' for each day. 
daily_totals = menu_item_sales.groupby('DATE')['ORDER_TOTAL'].sum().reset_index()


# --- Chart Setup ---

# Calculate the range of sales values to set a dynamic y-axis scale.
min_value = daily_totals['ORDER_TOTAL'].min()
max_value = daily_totals['ORDER_TOTAL'].max()

# Calculate a margin to add above and below the min/max values on the chart.
chart_margin = (max_value - min_value) / 2
y_margin_min = min_value - chart_margin
y_margin_max = max_value + chart_margin

# Create a line chart.
chart = alt.Chart(daily_totals).mark_line(
    point=True,     
    tooltip=True
).encode(
    x=alt.X('DATE:T',
            axis=alt.Axis(title='Date', format='%b %d'),
            title='Date'),
    y=alt.Y('ORDER_TOTAL:Q',
            axis=alt.Axis(title='Total Sales ($)'), 
            title='Total Daily Sales',
# Set a custom domain (range) for the y-axis to add padding dynamically. 
            scale=alt.Scale(domain=[y_margin_min, y_margin_max]))
).properties(
    title=f'Total Daily Sales for Menu Item: {selected_menu_item}',
    height=500
)


# --- Displaying the Chart ---

# Render the Altair chart in the Streamlit app.
# 'use_container_width=True' makes the chart expand to the full width of the container.
st.altair_chart(chart, use_container_width=True)