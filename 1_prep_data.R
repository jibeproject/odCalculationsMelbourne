suppressPackageStartupMessages(library(RPostgreSQL))
suppressPackageStartupMessages(library(sf)) # for spatial things
suppressPackageStartupMessages(library(data.table)) # 
suppressPackageStartupMessages(library(dplyr)) # for manipulating data
# suppressPackageStartupMessages(library(igraph)) # make network graphs
suppressPackageStartupMessages(library(nngeo)) # nearest neighbor



# prep origins and destinations -------------------------------------------


# points <- read.csv("C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/mandatory_tours_geometry_clean.csv")
points <- read.csv("C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/All_Trips_OD_Purpose.csv")

origins <- points %>%
  mutate(id=row_number()) %>%
  dplyr::select(id,tripid,lat=origlat,lon=origlong) 
origins_sf <- origins %>%
  st_as_sf(coords=c("lon","lat"),crs=4326)

destinations <- points %>%
  mutate(id=row_number()) %>%
  dplyr::select(id,tripid,lat=destlat,lon=destlong) 
destinations_sf <- destinations %>%
  st_as_sf(coords=c("lon","lat"),crs=4326)

st_write(origins_sf,"C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/origins_sf.sqlite",delete_dsn=T)
st_write(destinations_sf,"C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/destinations_sf.sqlite",delete_dsn=T)


