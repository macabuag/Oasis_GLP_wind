# -*- coding: utf-8 -*-
"""
Created on Tue Oct 27 09:30:31 2020

@author: silvia Bertelli

Description: Functions for running Oasis Model
"""
############################ LOAD LIBRARIES ###################################
import os
import sys
from pathlib import Path
import glob
import numpy as np
import pandas as pd
import math
import geopandas as gpd
import matplotlib.pyplot as plt 
from shapely.geometry import Polygon, MultiPoint, Point, box
import pprint
import folium

from matplotlib.colorbar import Colorbar
from matplotlib.offsetbox import AnchoredText
from mpl_toolkits.axes_grid1 import AxesGrid

#call the python code for the windstorm estimation
#import windfield_TEST_SPYDER as wnf
#import storm_database as sd

############################## FUNCTIONS ######################################

### Unit conversion

def get_mph(velocity):
    """
    convert m/s to miles per hour [mph].
    """
    velocity = velocity * 3600 /1852
    
    return velocity

# Function to convert latitude and longitude to decimal degree:
def dms2dd(s):
    """convert lat and long to decimal degrees"""
    direction = s[-1]
    degrees = s[0:4]
    dd = float(degrees) 
    if direction in ('S','W'):
        dd*= -1
    return dd

# Function to convert from nautical miles to kilometers:
def nmiles_to_km(N):
    """convert nautical miles to km"""
    N = N * 1.852
    return N

#Function to convert velocity from knot to m/s (NOTE: double check this formula)  
def knot_to_msec(Velocity):
    """convert Knots (= natucal miles per hour) to m/s:
        1 Knot = 1852 meters per hour; 1 h = 3600s"""
    Velocity = Velocity * 1852 / 3600
    return Velocity

### Distance estimation

#Function to estimate the distance between two points in decimal degree based 
#on the __Harvesine law__.
#Check Wikipedia for more information on its formulation: 
    #https://en.wikipedia.org/wiki/Haversine_formula

def haversine(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """

    #Convert decimal degrees to Radians:
    lon1 = np.radians(lon1.values)
    lat1 = np.radians(lat1.values)
    lon2 = np.radians(lon2.values)
    lat2 = np.radians(lat2.values)

    #Implementing Haversine Formula: 
    dlon = np.subtract(lon2, lon1)
    dlat = np.subtract(lat2, lat1)

    a = np.add(np.power(np.sin(np.divide(dlat, 2)), 2), 
               np.multiply(np.cos(lat1), 
                           np.multiply(np.cos(lat2),
                                       np.power(np.sin(np.divide(dlon, 2)), 
                                                2))))
    c = np.multiply(2, np.arcsin(np.sqrt(a)))
    r = 6372.795477598 # approximate radius of earth in km

    return c*r 

### Geolocalization

#Convert the dataframe in a geodataframe, and apply the coordinate system WGS84
def geolocalization(df):
    """function to convert the database in a geodatabase and add the coordiate
    system WGS84 (("EPSG:4326")"""
    gdf = gpd.GeoDataFrame( df, geometry=gpd.points_from_xy(
        x=df.Lon, y=df.Lat),
        crs = "EPSG:4326")
    return gdf

#Re-projcet the geodataframe from WGS 84 coordinate system to EPSG XXXX 
#coordinate system. Please specify the new coordinate system with the following
#format when calling this function: "EPSG:XXXX"

def reproject(gdf, EPSG):
    """ convert a geodataframe from WGS84 ("EPSG:4326") coordinate system to 
    another EPSG coordinate system of your choice"""
    gdf = gdf.to_crs(EPSG)
    return gdf

### Area_peril

def get_admin(admin, projected_crs):
    """ 
    Inputs:
    -------
        - shapefile of admin bundaries;
    Description:
    -----------
        - load the shapefile and convert it to a geodatagrame;
        - projected the geodataframe to the selected CRS;
        - plot the geodataframe;
    Returns:
    -------
        - geodataframe 
    """
    #load the shp
    gdf_admin = gpd.read_file(admin)
    #print(gdf_admin.crs)
    gdf_admin = gdf_admin.to_crs(projected_crs)
    
    #plot the country
    gdf_admin.plot(color = 'white', edgecolor ='k', linewidth=0.5)
    plt.axis("off")
    plt.show()
    
    return gdf_admin

def get_extent(gdf_admin):
    """
    Inputs:
    -------
        - admin geodataframe;
        - projected crs (i.e. Guadaloupe is 2970; check on: https://epsg.io/2970)
    
    Description:
    -----------
        This function take the admin geodataframe and create a grid over it
    
    Returns:
    -------
        - extension bundaries of the admin geodataframe

    """
    data = gdf_admin.total_bounds
    # create a dataframe: lat = y and lon = x
    column_names = ['min_x', 'min_y', 'max_x', 'max_y']
    df_extent = pd.DataFrame(data=data, index = column_names)
    df_extent = df_extent.transpose()
    return df_extent

def buffer_grid(gdf_admin, radius):
    """ Take the geodataframe of the admin boundaries and do a buffer based on 
    a specified radius"""
    data = gdf_admin.total_bounds
    box_data = box(*data)
    buffer = box_data.buffer(radius)
    bounds_extent = buffer.bounds
    return bounds_extent

def get_grid(bounds_extent, height, width, projected_crs,fp_grid):
    """ 
    Inputs:
    -------
        - admin geodataframe;
        - height and width of each square of the grid (grid resolution);
        - projected crs (i.e. Guadaloupe is 2970; check on: https://epsg.io/2970)
    
    Description:
    -----------
        This function take the admin geodataframe and create a grid over it; 
        save the grid as shapefile.
    
    Returns:
    -------
        - grid
    """
    #shapefile boundaries
    xmin,ymin,xmax,ymax = bounds_extent
    #count number of rows/column 
    rows = abs(int(np.ceil((ymax-ymin) /  height)))
    cols = abs(int(np.ceil((xmax-xmin) / width)))
    #divide the area_peril in a grid
    XleftOrigin = xmin
    XrightOrigin = xmin + width
    YtopOrigin = ymax
    YbottomOrigin = ymax- height
    polygons = []
    for i in range(cols):
        Ytop = YtopOrigin
        Ybottom =YbottomOrigin
        for j in range(rows):
            polygons.append(Polygon([(XleftOrigin, Ytop), 
                                     (XrightOrigin, Ytop), 
                                     (XrightOrigin, Ybottom), 
                                     (XleftOrigin, Ybottom)])) 
            Ytop = Ytop - height
            Ybottom = Ybottom - height
        XleftOrigin = XleftOrigin + width
        XrightOrigin = XrightOrigin + width
    #create a geodataframe of the grid
    grid = gpd.GeoDataFrame({'geometry':polygons})
    #set the ID for each polygon 
    grid['AREA_PERIL_ID'] = grid.index + 1
    grid = grid.set_crs(projected_crs)
    grid.to_crs("EPSG:4326")
    grid.to_file(fp_grid)
    return grid

def get_grid_vertices(grid, projected_crs): #https://stackoverflow.com/questions/58844463/how-to-get-a-list-of-every-point-inside-a-multipolygon-using-shapely
    """ 
    Inputs:
    -------
        - grid;
        - projected crs 
    
    Description:
    -----------
        Convert the vertices of the grid in nodes and extract the correspondent
        latitude and longitude; save the nodes as shapefile
    
    Outputs:
    -------
        - geodataframe of the nodes of the grid
    """    
    col = grid.columns.tolist()
    nodes = gpd.GeoDataFrame(columns=col)
    for index, row in grid.iterrows():
        for pt in list(row['geometry'].exterior.coords[:-1]): 
            nodes = nodes.append({'AREA_PERIL_ID':row['AREA_PERIL_ID'], 'geometry':Point(pt) },ignore_index=True)
    
    nodes = nodes.set_crs(projected_crs)
    nodes = nodes.to_crs("EPSG:4326")
    nodes['lon'] = nodes['geometry'].x
    nodes['lat'] = nodes['geometry'].y
    #nodes.to_file(fp_nodes)
    return nodes
    
def get_grid_centroid(grid, projected_crs):
    centroids = grid.copy()
    centroids.geometry = centroids['geometry'].centroid
    centroids = centroids.to_crs("EPSG:4326")
    centroids['Centro_Lon'] = centroids.geometry.x
    centroids['Centro_Lat'] = centroids.geometry.y
    #centroids.to_file(fp_centroids)
    return centroids
    
def convert_to_oasis_areaperil(nodes, peril, coverage):
    """ 
    Inputs:
    -------
        - nodes dataframe;
        - type of peril;
        - type of coverage
    
    Description:
    -----------
        Convert the nodes dataframe to the oasis "area_id" dataframe format;
        save the new dataframe as csv file;
    
    Returns:
    -------
        - dataframe "area_peril_id"
    """     
    
    column_names = ['PERIL_ID', 'COVERAGE_TYPE', 
                     'LON1', 'LAT1',
                     'LON2', 'LAT2',
                     'LON3', 'LAT3',
                     'LON4', 'LAT4',
                     'AREA_PERIL_ID'
                     ]
    
    nodes.to_crs("EPSG:4326")   
    nodes['id'] = nodes.groupby('AREA_PERIL_ID').cumcount()
    
    point3 = nodes.loc[nodes['id'] == 0].copy()
    point3.rename(columns={'lon': 'LON1', 'lat': 'LAT1'}, inplace=True)  
    point1 = nodes.loc[nodes['id'] == 1].copy()
    point1.rename(columns={'lon': 'LON2', 'lat': 'LAT2'}, inplace=True)
    point2 = nodes.loc[nodes['id'] == 2].copy()
    point2.rename(columns={'lon': 'LON3', 'lat': 'LAT3'}, inplace=True)
    point4 = nodes.loc[nodes['id'] == 3].copy()
    point4.rename(columns={'lon': 'LON4', 'lat': 'LAT4'}, inplace=True)

    dmerge = pd.merge(point3, point1, on='AREA_PERIL_ID', how='inner')
    dmerge = pd.merge(dmerge, point2, on='AREA_PERIL_ID', how='inner')
    dmerge = pd.merge(dmerge, point4, on='AREA_PERIL_ID', how='inner')
    dmerge = dmerge.drop(['id_x', 'id_y', 'geometry_x', 'geometry_y'], axis = 1)
    
    dmerge['PERIL_ID'] = peril
    dmerge['COVERAGE_TYPE'] = coverage
    
    #rename and reorder columns
    df_areaperil = dmerge[column_names]
    return df_areaperil

def concatenate_df_areaperil(frames_areaperil, fp_areaperil):
    df_areaperil = pd.concat(frames_areaperil)
    #save as csv
    df_areaperil.to_csv(fp_areaperil, index=False)
    return df_areaperil

def areapeeril_map(area_peril_dictionary,latitude, longitude):
    """ plot the area_peril_dictionary on a folium map"""
    m = folium.Map(location=[latitude, longitude], zoom_start=11, tiles='cartodbpositron')
    area_peril_dictionary['lat']=area_peril_dictionary['LAT1']
    area_peril_dictionary['lon']=area_peril_dictionary['LON1']
    num_cells = area_peril_dictionary.lat.count()
    num_cells_per_side = math.sqrt(num_cells)
    cell_size_lat = (max(area_peril_dictionary.lat) - min(area_peril_dictionary.lat)) / (num_cells_per_side - 1)
    cell_size_lon = (max(area_peril_dictionary.lon) - min(area_peril_dictionary.lon)) / (num_cells_per_side - 1)
    for i, row in area_peril_dictionary.iterrows():
        geometry = [Polygon([
            (row.lon, row.lat),
            (row.lon, row.lat + cell_size_lat),
            (row.lon + cell_size_lon, row.lat + cell_size_lat),
            (row.lon + cell_size_lon, row.lat)])]        
        crs = 'epsg:4326'
        d = {'Description': ['All']}
        df = pd.DataFrame(data=d)
        gdf = gpd.GeoDataFrame(df, crs=crs, geometry=geometry)
        folium.GeoJson(gdf).add_to(m)
    
    m.save("extent_map.html")
    return m

### windfield calculation

def load_STORM(file, filenumber):
    """ import txt files, add the header, add an ID column and export as csv"""
    df = pd.read_csv(file, sep=",", header = None, skiprows=[0],
                     names=("Year", "Month", "TCnumber", "TimeStep", "BasinID", 
                            "Lat", "Lon","Press_hPa", "Vmax_ms", "RMW_km",
                            "Category", "Landfall", "Dist_km")) 
    
    #add wind category
    df['V'] = df['Vmax_ms']
    df.loc[:,'category'] = df.apply(get_wind_category,axis=1)
    
    #add file name
    df['source'] = file.name
    df['filenumber'] = filenumber
    df['Year'] = df.Year.astype(int)
    df['Month'] = df.Month.astype(int)
    df['TCnumber'] = df.TCnumber.astype(int)
    
    #set ID column
    df['ID_event'] = df.filenumber.astype(str) + df.Year.astype(str) +  df.Month.astype(str) +  df.TCnumber.astype(str)
    # clean the dataframe   
    usecols = ['ID_event','Year', 'Month', 'TimeStep', 'Lat', 'Lon','Vmax_ms', 'RMW_km', 'category', 'source']  
    df_clean = df[usecols].copy() 
    
    # save as csv
    #df_clean.to_csv(fp_storm_csv, index=False)
    return df_clean

def load_multiple_STORM(gdf_admin, distance_wind, cat_wind, fp_out):
    ''' Takes all textfiles in folder ('inputs/STORM/'), 
    estimates the centroid of the country. 
    Narrows down storms based on distance from centroid.'''
    source_files = sorted(Path('../model_data/storm').glob('*.txt'))
    gdf_admin_centroid = centroid_admin(gdf_admin)

    dataframes = []
    filenumber = 0
    for file in source_files:
        df_storm = load_STORM(file, filenumber)
        gdf_storm = geolocalization(df_storm)
        storm_dist = get_distance(gdf_storm, gdf_admin_centroid)
        df = select_events(storm_dist, distance = distance_wind, category = cat_wind) #ToDo: Move all hard-coded variables to top of code
        filenumber += 1
        
        dataframes.append(df)

    database = pd.concat(dataframes)
    # save as csv
    database.to_csv(fp_out, index=False)
    return database

def centroid_admin(gdf_admin):
    gdf_admin_centroid = gdf_admin.copy()
    gdf_admin_centroid['geometry'] = gdf_admin_centroid['geometry'].centroid

    #reproject in decimal degree
    gdf_admin_centroid = reproject(gdf_admin_centroid, EPSG = 4326)  #centroid of the country in decimal degree 


    # save lat and lon in two different columns
    gdf_admin_centroid['Lat_admin'] = gdf_admin_centroid.geometry.y
    gdf_admin_centroid['Lon_admin'] = gdf_admin_centroid.geometry.x
    return gdf_admin_centroid

def get_distance(gdf_storm, gdf_centroid_admin):
    df_wind = (gdf_storm.assign(key=1)                  #
          .merge(gdf_centroid_admin.assign(key=1), on="key")
          .drop("key", axis=1))

    # estimate the distance with the harvesine formula
    df_wind['r_km'] = haversine(df_wind['Lon'], df_wind['Lat'], df_wind['Lon_admin'], df_wind['Lat_admin'])
    return df_wind

def select_events(df_wind, distance, category):
    #select rows with r_km minor than the distance
    df = df_wind.copy()
    df = df.loc[df['r_km'] < distance]
    
    # get the corresponding list of unique values in ID_events
    events_ID = df.ID_event.unique()
    
    #select the events
    df1 = df_wind.copy()
    df1 = df1.loc[df1['ID_event'].isin(events_ID)]
    
    #select rows with category greater than X
    df2 = df1.loc[df1['category'] >= category]
    # get the corresponding list of unique values in ID_events
    events_ID2 = df2.ID_event.unique()
       
    #clean dataframe
    columns_selection = ['ID_event', 'Year', 'Month', 
                         'TimeStep', 'Lat', 'Lon', 'Vmax_ms',
                         'RMW_km', 'category', 'r_km', 
                         'source']
    
    df3 = df1[columns_selection].copy()
    df3 = df3.loc[df3['ID_event'].isin(events_ID2)]
    
    #save as csv
    #df3.to_csv(fp_storm_selection, index=False)
    #save shapefile
    gdf = geolocalization(df3)
    #gdf.to_file(fp_storm_shp)
    return gdf
  
def STORM_analysis(df):
    df['B'] = B_P05(df['Vmax_ms'], df['Lat'])
    df.drop('r_km', axis=1, inplace=True)
    return df

#The following function load the data from the __Hurdat database__ and apply 
#the unit conversions:
    #-  Convert latitude and longitude in decimal degree;
    #-  convert the wind velocity from [knot] to [m/s];
    #-  Estimate the Radius of maximum wind according to Willoughby and Rahn 
        #(2006) (you can select a different function from the ones available 
        #on section 4.1)
    #-  Estimate the Holland parameter B according to Powell et al (2005);
    
def load_data_hurdat(fp):
    """ inport the excel file of the windstorm database and apply unit 
    convertions"""
    
    df = pd.read_excel(fp, header = None, skiprows=[0], 
                       names=("YYMMDD", "Hours", "Status", "Lat", "Lon",
                              "Vmax_kts", "Pmax_mb", 
                              "34_r_NE", "34_r_SE", "34_r_SW", "34_r_NW",
                              "50_r_NE", "50_r_SE", "50_r_SW", "50_r_NW", 
                              "64_r_NE", "64_r_SE", "64_r_SW", "64_r_NW"))
       
    df['Lat'] =  df['Lat'].apply(dms2dd)
    df['Lon'] =  df['Lon'].apply(dms2dd)
    df['Vmax_ms'] = df['Vmax_kts'].apply(knot_to_msec)
    df['RMW_km'] = Rmax_W06(df['Vmax_ms'], df['Lat'])
    df['B'] = B_P05(df['Vmax_ms'], df['Lat'])
    
    df_clean = df[['YYMMDD','Hours','Lat','Lon', 'Vmax_ms', 'Rmax_km', 
                   'B']].copy()
    return df_clean

#The following function load the data from the IBTrACS database and 
#apply the unit conversions.

def load_data_IBTrACS(fp):
    """ inport the csv file of the windstorm database and apply unit 
    convertions"""  
    
    df = pd.read_csv(fp, sep = ',', header = 0)
    
    usecols = ['Year','Month', 'Day','Hour', 'Lat', 'Lon', 'Vmax_ms', 
               'RMW_km', 'B']
        
    #convert the column 'ISO_TIME' in data time format
    df['ISO_TIME'] = pd.to_datetime(df['ISO_TIME'], errors='coerce')
    df['Year'] = df['ISO_TIME'].dt.year
    df['Month'] = df['ISO_TIME'].dt.month
    df['Day'] = df['ISO_TIME'].dt.day
    df['Hour'] = df['ISO_TIME'].dt.hour
    
    #replace missing values with a zero and convert to float
    df['USA_RMW'] = df['USA_RMW'].fillna(0)
    df['USA_RMW'] = pd.to_numeric(df['USA_RMW'], errors='coerce')
    
    #apply convertions
    df['Lat'] = df['LAT']
    df['Lon'] = df['LON']
    df['Vmax_ms'] = df['USA_WIND'].apply(knot_to_msec)
    df['RMW_km'] = df['USA_RMW'].apply(nmiles_to_km)
    
    #estimate the B Holland parameter
    df['B'] = B_P05(df['Vmax_ms'], df['Lat'])
    
    #clean the dataframe
    df_clean = df[usecols].copy()   
    return df_clean

### Radius of maximum wind (Rmax)

def Rmax_W04(Vmax, Lat):
    """ Estimation of the radius of maximum wind according to the formula 
    proposed by Willoughby and Rahn (2004), eq. (12.1)
    Note: possibly under-estimating Rmax when compared to IBTrACS"""
    Rmax = 46.29 * (np.exp(-0.0153*Vmax + 0.0166*Lat))
    return Rmax #this is ok if the formula is in km

def Rmax_W06(Vmax, Lat):
    """ Estimation of the radius of maximum wind according to the formula 
    proposed by Willoughby and Rahn (2006), equation 7a"""
    Rmax = 46.4 * (np.exp(-0.0155*Vmax + 0.0169*Lat))
    return Rmax #this is ok if the formula is in km

def Rmax_Q11(Vmax):
    """ Estimation of the radius of maximum wind according to the formula proposed
    by Quiring et al. (2011); Vmax and Rmax are in nautical miles. 
    Expression herein converted in km"""
    Vm= Vmax * 0.5399568
    Rmax = ((49.67 - 0.24 * Vm)) * 1.852 
    return Rmax

### Holland shape parameter (B)
def B_P05(Vmax,Lat):
    """ Holland parameter B estimated with the statical regression formula 
    proposed by Powell et al (2005), eq.(12.2)"""
    b_shape = 0.886 + 0.0177 * Vmax - 0.0094 * Lat
    return b_shape

###  Wind speed

#The following formulas for the windfield calculation refers to the 
#Grey and Liu (2019) paper.

def wind_speed(Vmax, Rmax, r, B):
    """ cyclonic wind speed calculation according to 
    according to Grey and Liu (2019); 
    Note: the formula has been devided in x and y to ease the computation"""
    x = 1 -((Rmax / r) ** B)
    y = (Rmax / r) ** B
    Vc = Vmax * (y * np.exp(x)) ** 0.5
    return Vc

def b(r, Rmax):
    """ Inflow angle of the cyclonic wind fields direction 
    according to Grey and Liu (2019)"""
    if r < Rmax:
        b = 10 * r / Rmax
    elif r >= 1.2*Rmax:
        b = 10
    else:
        b = (75 * r / Rmax) - 65
    return b

### Wind categorization 
def get_wind_category(row):
    """ define the Hurricane category according to the Saffir- Simpson 
    Hurrican Scale.
    Note: the scale is for a [m/s] wind velocity"""
    
    if row.V <= 33:
        return 0
    elif 33 < row.V <= 42:
        return 1
    elif 42 < row.V <= 49: 
        return 2
    elif 49 < row.V <= 58: 
        return 3
    elif 58 < row.V <= 70: 
        return 4
    else:
        return 5
    
### Events

def unique_events(df):
    """ Create a dataframe with the unique event_id and save as csv file 
    as input files for oasis"""
    
    events = df.filter(['ID_event', 'Year', 'Month'], axis=1)
    events = events.drop_duplicates()  

    df_events = pd.DataFrame(events)
    df_events = df_events.reset_index()
    df_events['event_id'] = df_events.index + 1
    
    df_events = df_events.drop(['index'], axis=1)   
    return df_events

def merge_unique_events_windtrack(df_events, windtrack, fp_wind):
    """ add the oasis event_id number to the windtrack dataframe"""  
    df = pd.merge(windtrack, df_events, on="ID_event")
    gdf = geolocalization(df)
    gdf.to_file(fp_wind, driver='ESRI Shapefile')
    return gdf
    

def oasis_events(df_events, fp_events):
    df_osasis_events = df_events.copy()
    df_osasis_events = df_osasis_events.drop(['ID_event', 'Year', 'Month'], axis=1)      
    #save as csv
    df_osasis_events.to_csv(fp_events, index=False)
    return df_osasis_events
    
def oasis_occurence(df_events, fp_occurrence):
    """ create a dataframe with the unique event_id and correspondent occurence;
    save it as csv file for oasis lmf"""
    occurence = df_events.copy()
    occurence = occurence.drop(['ID_event'], axis=1)  
    df_occurence = pd.DataFrame(occurence)
    #column names as in oeasis
    df_occurence['period_no'] = df_occurence.Year
    df_occurence['occ_year'] = df_occurence.Year
    df_occurence['occ_month'] = df_occurence.Month
    df_occurence['occ_day'] = df_occurence.Month
    #select columns
    columns_selected = ['event_id', 'period_no', 'occ_year', 'occ_month', 'occ_day' ]
    df_osasis_occurence = df_occurence[columns_selected]
    #save as csv
    df_osasis_occurence.to_csv(fp_occurrence, index=False)
    return df_osasis_occurence

# Intensity dictionary

def load_intensity(intensity_dic):
    #load the csv
    df_intensity = pd.read_csv(intensity_dic, sep=',')#, index_col='bin_index')
    return df_intensity

# Footprint

def merge_wind_w_grid(wind_points, grid_centro):
    """ 
    Inputs:
    -------
        - windtrack dataframe;
        - grid dataframe;
    
    Description:
    -----------
        - Merge the two dataframe;
        - Estimate the distance between each windtrack point and the centre of 
        of each centroid of the grid;
        - estimate the wind velocity at the centroid [Vc in m/s];
        - convert the velocity to nautical miles per hour;
        -export the combined dataframe as csv
    Returns:
    -------
        - combined dataframe 
    """
    
    df = (wind_points.assign(key=1)
          .merge(grid_centro.assign(key=1), on="key")
          .drop("key", axis=1))
    #estimate the distance in km
    df['r_km'] = haversine(df['Lon'], df['Lat'], df['Centro_Lon'], df['Centro_Lat'])
    
    #estimate the velocity
    df['Vc_ms'] = wind_speed(df['Vmax_ms'], df['RMW_km'], df['r_km'] ,df['B'])
    
    df ['Vc_mph'] = get_mph(df['Vc_ms']) 
    #save the combine dataframe as csv file
    #df.to_csv(fp_combine_1, index=False)
    return df

def groupby_grid(df):
    df_max = df.groupby(['AREA_PERIL_ID', 'Centro_Lon', 'Centro_Lat', 'event_id' ], as_index=False).agg({
    'Vc_mph': max, 
    'r_km': min, 
    'RMW_km': max,
    'Vmax_ms':max,
    'B': 'mean'}).reset_index().copy()
    #df_max.to_csv(fp_groupby_1, index=False)
    return df_max

def intensity_lookup(df_intensity, df_max):
    
    #create a key called 'event_id' for merging the dataframe
    df_max = df_max.assign(key=1).merge(
        df_intensity.assign(key=1), on='key', how='outer')
    
    #merge the two database
    df_merge = df_max[(df_max['bin_from'] < df_max['Vc_mph']) 
                      &  (df_max['bin_to'] > df_max['Vc_mph'])]
    #export as csv
    #df_merge.to_csv(fp_groupby_2, index=False)
    #print(df_merge.head())
    return df_merge
    
def get_footprint(df_merge, fp_footprint):
    
    #list of columns in the footrpint dataframe
    footprint_columns = ['event_id', 'AREA_PERIL_ID', 'bin_index', 'probability']
    
    # create the probability column and assign the value 1 #### NOTE THIS MIGHT BE MODIFIED IN THE FUTURE TO CHANGE PROBABILITIES
    
    df_merge = df_merge.assign(probability = 1)
    
    #clean the dataframe
    df_footprint = df_merge[footprint_columns].copy()
    
    #rename columns
    df_footprint = df_footprint.rename(columns = {
        'AREA_PERIL_ID':'areaperil_id',
        'bin_index':'intensity_bin_id'})
    df_footprint =  df_footprint.sort_values(by=['event_id', 'areaperil_id'])
    #save as csv
    df_footprint.to_csv(fp_footprint, index=False)
    return df_footprint

### 5. Damage intensity   
    
# damage dictionary 
def load_damage_dic(damage_dic):
    df_damage_dic = pd.read_csv(damage_dic, sep=',', header=0)
    return df_damage_dic

# combine vulnerability with damage

def damage_intensity_lookup(df_val_vf, df_damage_dic, df_intensity):
    #create a key called 'key' for merging the dataframe
    df = df_val_vf.assign(key=1).merge(
        df_damage_dic.assign(key=1), on='key', how='outer')
    
    #merge the two database
    df_merge = df[(df['bin_from'] < df['Damage']) 
                      &  (df['bin_to'] > df['Damage'])]
    # create intensity key
    df2 = df_merge.merge(df_intensity.assign(key=1), on='key', how='outer')
    #merge the two database
    df_merge2 = df2[(df2['bin_from_y'] < df2['IM_mph']) 
                      &  (df2['bin_to_y'] > df2['IM_mph'])]
    #set probabilities
    #df_merge2.loc[:,'probability'] = 1
    #export as csv
    #df_merge2.to_csv(fp_groupby_vf1, index=False)
    return df_merge2

### 6. Vulnerability

# Load the vulnerability database
def load_vf(fp, fp_out):
    """load the database with all vulnerability functions, and save each row
    as a separate file"""
    df_vf = pd.read_csv(fp, sep=',', header = 0)   
    #iteration
    for i, g in df_vf.groupby('rowNum'):
       g.to_csv(fp_out.format(i), index = False)
    return df_vf

def plot_multi_vf(path_vf_out):
    """ load dataframe of vulnerability function and export them as single csv file"""
    source_files = sorted(Path('../model_data/vulnerability/vf_by_name/').glob('*.csv'))
     
    #set an iterator
    filenumber = 0
    dataframes = []
    # for loop
    for file in source_files:
        #print(file)
        df1=pd.read_csv(file, header=0, sep=',')
        #print(df1.columns)
        df_val_vf = get_values_vf(df1)
        name = df1.loc[0,'Name']
        #print(name)
        
        df_val_vf.to_csv(os.path.join(path_vf_out, name + ".csv") , index=False)
        
        #create and save figure
        y = df_val_vf.Damage
        x = df_val_vf.IM_mph
        fig, ax = plt.subplots()
        ax.plot(x,y, color = 'darkred')
        ax.grid(ls = ':')
        ax.set_xlabel('Intensity [mph]')
        ax.set_ylabel('Damage [%]')
        plt.tight_layout()
        plt.savefig(os.path.join(path_vf_out, name + ".png"), format="PNG")
        plt.close()
        
        dataframes.append(df_val_vf)
        
        filenumber += 1
    
    database = pd.concat(dataframes)
    database.to_csv( os.path.join(path_vf_out, "database_vf" + ".csv") , index=False)
    return database
    
def get_values_vf(df_vf):
    # indicate the colum values (list)
    y = df_vf.Y_vals 
    x = df_vf.IM_c #intensity measure in m/s
    
    vulnerability_id = int(df_vf.ID_set)
    
    # convert list to a new dataframe
    df_y = pd.DataFrame([sub.split(",") for sub in y])
    df_y = df_y.astype(float)
    df_y = df_y / 100 
    df_x = pd.DataFrame([sub.split(",") for sub in x])
    df_x = df_x.astype(float)
    
    #transpose columns to row
    df_y_transposed = df_y.transpose()
    df_x_transposed = df_x.transpose()
    #print(df_x_transposed.info())
    #print(df_y_transposed.tail())
    
    #concatenate database along column
    df_val_vf = pd.concat([df_y_transposed,df_x_transposed], axis=1).copy()
    df_val_vf.columns = ['Damage', 'IM_c']
    #print(df_val_vf)
    #print(df_val_vf.info())
    #print(df_val_vf.head())
    df_val_vf.columns = ['Damage', 'IM_c']
    
    df_val_vf['IM_mph'] = get_mph(df_val_vf['IM_c'])
    df_val_vf.loc[:, 'VULNERABILITY_ID'] = vulnerability_id
    
    #print(df_val_vf.tail())
    #save as csv
    #df_val_vf.to_csv(fp_vf, index=False)
    return df_val_vf

def plot_values_vf(df_val_vf):
    y = df_val_vf.Damage
    x = df_val_vf.IM_mph
    fig, ax = plt.subplots()
    ax.plot(x,y, color = 'darkred')
    ax.grid(ls = ':')
    
    ax.set_xlabel('Intensity [mph]')
    ax.set_ylabel('Damage [%]')
    plt.tight_layout()
    
    # for saving multiple figures
    #plt.savefig(os.getcwd()+ file +'.pdf',figsize=(5,5),dpi=600)
    plt.show()
    
def vulnerability_dic(df_val_vf, gar_dict, fp_vf_dic):
    
    select_columns = ['ID_set', 'Name', 'Coverage', 'Hazard']
    df = df_val_vf[select_columns].copy()
    
    #set peril values as in oasis
    df.loc[(df.Hazard == 'Wind'), 'PERIL_ID'] = 'WTC'

    #set coverage
    # coverage = 0 : No deductible / limit
    # coverage = 1 : Building
    # coverage = 2 : Other (typically appurtenant structures)
    # coverage = 3 : Contents
    # coverage = 4 : Business Interruption (BI)
    # coverage = 5 : Property Damage (PD: Building + Other + Contents)
    # coverage = 6 : All (PD + BI)
    
    df.loc[(df.Coverage == 'Buildings'), 'COVERAGE_TYPE'] = 1
    #df.loc[(df.Coverage == 'Buildings'), 'COVERAGE_TYPE'] = 3 #this should be a different coverage in the vulnerability dataset
       
    #occupancy code
    
    #df.loc[(df.Name == 'C1M L EDU PRIVATE'), 'OCCUPANCYCODE'] = 1102 #change occupancy code
    #df['OCCUPANCYCODE'] = 1102
    df = df.merge(gar_dict, on ='ID_set')
    
    #set the vulnerability_id
    df.rename(columns = {'ID_set':'VULNERABILITY_ID', 'OED Code': 'OCCUPANCYCODE'}, inplace = True)
    df.drop_duplicates()
    
    # columns as in oasis
    columns_oasis = ['PERIL_ID', 'COVERAGE_TYPE', 'OCCUPANCYCODE', 'VULNERABILITY_ID']
    df_vf_dic = df[columns_oasis].copy()
    df_vf_dic = df_vf_dic.drop_duplicates()
    #save as csv
    df_vf_dic.to_csv(fp_vf_dic, index=False)
    return df_vf_dic


def read_gar_vf(fp):  
    """ 
    Inputs:
    -------
        - dat file from GAR vulnerability
    Description:
    -----------
        - load the file and convert it to a datagrame;

    Returns:
    -------
        - dataframe
    """
    df = pd.read_table(fp, sep=",", skiprows=2, names = ["GAR_vf", "StructuralPeriod", "FileName"])#, usecols=['TIME', 'XGSM'])
    #print(df)
    #df.to_csv(fp_test, index = False)
    return df

def gar_dict(df_gar, df_vf):
    """ temporary function to merge the GAR dat file with the vulnerability 
    database, in order to create a unique link for the OED Occupancy code.
    The aim is to have a GAR dictionary to link different files"""
    
    df_gar['FileName'] = df_gar['FileName'].astype(str)
    df_vf['FileName'] = df_vf['FileName'].astype(str)
    
    df_merge = df_vf.merge(df_gar, on = 'FileName')
    
    select_columns = ['GAR_vf', "StructuralPeriod", 'FileName', 'OED Code', 'ID_set']
    
    df = df_merge[select_columns].copy()
    df = df.drop_duplicates()
    #df.to_csv(fp_test2, index = False)
    return df

def get_vulnerability(df_merge_2, fp_vulnerability):
    df = df_merge_2.copy()
    
    #set probabilities
    df.loc[:,'probability'] = 1
    
    df.rename(columns = {'VULNERABILITY_ID':'vulnerability_id',
                         'bin_index_y':'intensity_bin_id',
                         'bin_index_x':'damage_bin_id',
                         }, inplace = True)
    
    
    
    columns_oasis_vf = ['vulnerability_id','intensity_bin_id', 'damage_bin_id',
                        'probability']
    
    # dropping ALL duplicte values 
    df.sort_values(["vulnerability_id","intensity_bin_id"], inplace = True)
    df.drop_duplicates( subset = ["vulnerability_id","intensity_bin_id"],
                       keep = 'last', inplace = True)
    
    df_osasis_vulnerability = df[columns_oasis_vf]
    
    #export as csv
    df_osasis_vulnerability.to_csv(fp_vulnerability, index=False)
    
    return df_osasis_vulnerability

###  Exposure

def get_exposure(gar):
    """ 
    Inputs:
    -------
        - exposure shapefile from the GAR database;
    
    Description:
    -----------
        Convert the shapefile to a geodataframe;
        add the WGS84 coordinate system and save again as shapefile.
    
    Returns:
    -------
        - geodataframe of exposure points
    """ 
    gdf_exposure = gpd.read_file(gar)
    gdf_exposure = gdf_exposure.set_crs("EPSG:4326")
    #gdf_exposure.to_file(fp_gar)
    return gdf_exposure
    
def get_location(exposure):
    """ 
    Inputs:
    -------
        - exposure geodatagrame; 
    
    Description:
    -----------
        Select the column from the dataframe that are in common with the oasis
        format; add latitude and longitude of each point in WGS84 format;
    
    Returns:
    -------
        - exposure geodataframe with latitude and longitude;
    """ 
    select_columns = ['ID_5X5', 'COUNTRY', 'CPX', 'USE_SECTOR',
                      'BS_TYPE', 'RES_TYPE', 'USE_CLASS',
                      'VALFIS', 'VALHUM', 'geometry', 'SE_VIENTO']
    
    location = exposure[select_columns].copy()
    location['Latitude'] = location['geometry'].y
    location['Longitude'] = location['geometry'].x
    return location

def lookup_occupancycode(gar_dict, df_exposure):
    """ 
    Inputs:
    -------
        - GAR dictionary
        - exposure file
    Description:
    -----------
        - Merge the exposure file with the gar dictionary
    Returns:
    -------
        - dataframe with occupancy code OED
    """    
    df_occ = pd.merge(df_exposure,gar_dict, left_on=['SE_VIENTO'],right_on=['GAR_vf'])
    return df_occ
 

def convert_to_oasis_exposure(df_occ, PortNumber, AccNumber, IsTenant, 
                              BuildingID, ConstructionCode, #OccupancyCode, disactivate occupancy code 
                              LocPerilsCovered, ContentsTIV, BITIV, CondNumber, fp):
    """ 
    Inputs:
    -------
        - Exposure dataframe with occupancy code and exposure;
        - missin values for the exposure dafarame according to the oasis format;
    
    Description:
    -----------
        convert the exposure dataframe into the oasis format and 
        save it as csv file
    
    Returns:
    -------
        - exposure geodataframe 
    """ 
    #list of column from the oasis dataframe
    list_columns = [
        'PortNumber',
        'AccNumber',
        'LocNumber',
        'IsTenant', 
        'BuildingID',
        'CountryCode',
        'Latitude',
        'Longitude',
        'OccupancyCode',
        'ConstructionCode',
        'LocPerilsCovered',
        'BuildingTIV',
        'ContentsTIV',
        'BITIV',
        'CondNumber',
        'PortNumber',
        'LocCurrency']
    
    LOC = df_occ.copy()
    LOC.rename(columns={
        #'ID_5X5': 'LocNumber', 
        'COUNTRY': 'CountryCode',
        'VALFIS': 'BuildingTIV',
        'OED Code' : 'OccupancyCode'
        }, inplace=True)
    
    #add the missing values to the correspondent column
    LOC['LocNumber'] = LOC.index #I set equal to the index as I had many locaton with the same value; they need to be unique!
    LOC['PortNumber'] = PortNumber
    LOC['AccNumber'] = AccNumber
    LOC['IsTenant'] = AccNumber
    LOC['BuildingID'] = BuildingID
    LOC['ConstructionCode'] = ConstructionCode
    LOC['LocPerilsCovered'] = LocPerilsCovered
    LOC['ContentsTIV'] = ContentsTIV
    LOC['BITIV'] = BITIV
    LOC['CondNumber'] = CondNumber
    LOC['LocCurrency'] = ' ' #set empty value

    exposure = LOC[list_columns].copy()
    # save the dataframe as csv file
    #exposure.to_csv(fp, index=False)   
    return exposure