# prep model and network --------------------------------------------------

library(r5r)
library(data.table)
library(sf)
library(dplyr)
library(tidyr)

data_path <- "./data_melb"

departure_datetime <- as.POSIXct("16-10-2019 07:45:00",
                                 format = "%d-%m-%Y %H:%M:%S")
max_walk_dist = 5000
max_bike_dist = Inf
max_trip_duration = 180L
walk_speed = 5 
bike_speed = 14 
max_rides = 3 # transit transfers, see detailed_itineraries() help
max_lts = 2 # cyclist stress, see detailed_itineraries() help

options(java.parameters = "-Xms2G")
options(java.parameters = "-Xmx10G")


# set up
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)

# Rules
# origin and destination have to be 'near' the road network.


# load origins and destinations -------------------------------------------

origins <- st_read("C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/origins_sf.sqlite")
origins <- bind_cols(origins%>%st_drop_geometry(),
                     origins%>%st_coordinates()) %>%
  dplyr::select(id=tripid,lat=Y,lon=X)


destinations <- st_read("C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/destinations_sf.sqlite")
destinations <- bind_cols(destinations%>%st_drop_geometry(),
                          destinations%>%st_coordinates()) %>%
  dplyr::select(id=tripid,lat=Y,lon=X)

# We want to do the calculations in chunks of 100 and save them in separate csvs
# This way if (when) it crashes or Windows "helpfully" resets the computed, we
# haven't lost much work. 
chunk_size <- 100
n_chunks <- ceiling(nrow(origins) / chunk_size)


# Car OD calculations -----------------------------------------------------

itinaries_car <- detailed_itineraries(  
  r5r_core,
  origins,
  destinations,
  mode = "CAR",
  mode_egress = "WALK",
  departure_datetime = departure_datetime,
  # max_walk_dist = 40000,
  # max_bike_dist = max_bike_dist,
  max_trip_duration = 1800,
  walk_speed = walk_speed,
  bike_speed = bike_speed,
  max_rides = 5,
  max_lts = max_lts,
  shortest_path = TRUE,
  n_threads = Inf,
  verbose = FALSE,
  progress = TRUE,
  drop_geometry = TRUE
)

itinaries_car_cons <- itinaries_car %>%
  mutate(duration=segment_duration+wait) %>%
  dplyr::select(from_id,to_id,duration,distance) %>%
  group_by(from_id,to_id) %>%
  summarise(duration=sum(duration,na.rm=T),distance=sum(distance,na.rm=T)) %>%
  ungroup() %>%
  mutate(mode="car")




# PT-walk OD calculations -------------------------------------------------

for(i in 1:n_chunks){  
  lower = ((i-1)*chunk_size+1)
  upper = min(nrow(origins),(i*chunk_size))
  
  itinaries_pt_walk <- detailed_itineraries(  
    r5r_core,
    origins[lower:upper,],
    destinations[lower:upper,],
    mode = "TRANSIT",
    mode_egress = "WALK",
    departure_datetime = departure_datetime,
    # max_walk_dist = 10000,
    # max_bike_dist = max_bike_dist,
    max_trip_duration = 180,
    walk_speed = walk_speed,
    bike_speed = bike_speed,
    max_rides = 3,
    max_lts = max_lts,
    shortest_path = TRUE,
    n_threads = Inf,
    verbose = FALSE,
    progress = TRUE,
    drop_geometry = TRUE
  )
  write.csv(itinaries_pt_walk,
            paste0(
              "C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/pt-walk/",
              sprintf("pt-walk_%03d", i),
              ".csv"),
            row.names=F)
  cat(paste0("calculated ",sprintf("%03d", i),"/",n_chunks," records \n"))
}



# PT-drive OD calculations ------------------------------------------------

for(i in 1:n_chunks){  
  lower = ((i-1)*chunk_size+1)
  upper = min(nrow(origins),(i*chunk_size))
  
  itinaries_pt_drive <- detailed_itineraries(  
    r5r_core,
    origins[lower:upper,],
    destinations[lower:upper,],
    mode = "TRANSIT",
    mode_egress = "CAR",
    departure_datetime = departure_datetime,
    # max_walk_dist = 10000,
    # max_bike_dist = max_bike_dist,
    max_trip_duration = 180,
    walk_speed = walk_speed,
    bike_speed = bike_speed,
    max_rides = 3,
    max_lts = max_lts,
    shortest_path = TRUE,
    n_threads = Inf,
    verbose = FALSE,
    progress = TRUE,
    drop_geometry = TRUE
  )
  write.csv(itinaries_pt_drive,
            paste0(
              "C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/pt-drive/",
              sprintf("pt-drive_%03d", i),
              ".csv"),
            row.names=F)
  cat(paste0("calculated ",sprintf("%03d", i),"/",n_chunks," records \n"))
}




# Combining mode outputs into single file ---------------------------------


# combine pt-walk files
outdir="C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/pt-walk/"
filesDF <- data.frame(
  location=list.files(outdir,pattern="*.csv",full.names=T),
  stringsAsFactors=FALSE
) %>% arrange(location)
itinaries_pt_walk <- lapply(filesDF$location,read.csv,header=T) %>%
  bind_rows()

itinaries_pt_walk_cons <- itinaries_pt_walk %>%
  mutate(duration=segment_duration+wait) %>%
  dplyr::select(from_id,to_id,duration,distance) %>%
  group_by(from_id,to_id) %>%
  summarise(duration=sum(duration,na.rm=T),distance=sum(distance,na.rm=T)) %>%
  ungroup() %>%
  mutate(mode="ptwalk")

# combine pt-drive files
outdir="C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/pt-drive/"
filesDF <- data.frame(
  location=list.files(outdir,pattern="*.csv",full.names=T),
  stringsAsFactors=FALSE
) %>% arrange(location)
itinaries_pt_drive <- lapply(filesDF$location,read.csv,header=T) %>%
  bind_rows()

itinaries_pt_drive_cons <- itinaries_pt_drive %>%
  mutate(duration=segment_duration+wait) %>%
  dplyr::select(from_id,to_id,duration,distance) %>%
  group_by(from_id,to_id) %>%
  summarise(duration=sum(duration,na.rm=T),distance=sum(distance,na.rm=T)) %>%
  ungroup() %>%
  mutate(mode="ptcar")


# combining the three processed modes
itinaries_combined <- bind_rows(
  itinaries_car_cons,
  itinaries_pt_walk_cons,
  itinaries_pt_drive_cons
) %>%
  pivot_wider(
    names_from=mode,
    values_from=c(duration,distance))

# itinaries_combined_tmp <- bind_rows(
#   itinaries_car_cons,
#   itinaries_pt_walk_cons,
#   itinaries_pt_drive_cons
# )
# write.csv(itinaries_combined_tmp,
#           "C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/ininaries_tmp.csv",
#           row.names=F)
# 
# itinaries_combined_tmp <- read.csv( "C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/ininaries_tmp.csv")
# 
# itinaries_combined <- itinaries_combined_tmp %>%
#   pivot_wider(
#     names_from=mode,
#     values_from=c(duration,distance))

write.csv(itinaries_combined,
          "C:/Users/e25730/OneDrive - RMIT University/Alan Both/DOT_VISTA/ininaries.csv",
          row.names=F)


