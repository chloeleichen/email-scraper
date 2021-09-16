library(readxl)
library(robotstxt)
library(dplyr)
library(tidyr)
library(stringr)
library(urltools)
library(rvest)

# replace file-path with actual file path
raw_file <- read_excel(file_path, sheet = "SchoolProfile 2020")
names(raw_file)<-str_replace_all(names(raw_file), c(" " = "." , "," = "" ))
data <- filter(raw_file, State == 'QLD' & School.Sector == 'Independent' & (School.Type=='Primary' | School.Type=='Combined'))%>% drop_na(School.URL)

data <-dplyr::filter(data, !grepl('https', School.URL))

urls <- data[['School.URL']]
names <- data[['School.Name']]


scheme <-url_parse(urls)[['scheme']]
domain <- suffix_extract(domain(urls))['domain']
host <- suffix_extract(domain(urls))[['host']]
pattens <- str_remove(host, "www.")
pattens <- str_c("@", pattens)
contact_pages_1 <- paste0(scheme, '://', host, '/contact')
contact_pages_2 <- paste0(scheme, '://', host, '/contact-us')
contact_pages_3 <- paste0(scheme, '://', host, '/get-in-touch')
# TODO auto generate
fuzzy_xpath <- "//*[contains(text(), 'admin@') or contains(text(), 'enquires@') or contains(text(), 'info@') or contains(text(), 'reception@') or contains(text(), 'principal@')]"

get_email <- function(url, xpath){
  out <- tryCatch(
    {
      print(url)
      page <- read_html(url)
      email_html <- html_nodes(page,xpath=xpath)
      if(length(email_html) == 0){
        email_html <- html_nodes(page,xpath=fuzzy_xpath)
      }
      
      emails <- html_text(email_html, trim = TRUE)
      if(length(emails)==0){
        emails<- html_attr(email_html,"href")
      }
      
      links <- str_extract(emails, "\\S*@\\S*")
      return(links)
    },
    error=function(cond) {
      print(cond)
      # Choose a return value in case of error
      return(NULL)
    },
    warning=function(cond) {
      print(cond)
      # Choose a return value in case of warning
      return(NULL)
    }
  ) 
}

subset = urls[5]
pattens_subset = pattens[5]
contact_page1 = contact_pages_1[5]
contact_page2 = contact_pages_2[5]
contact_page3 = contact_pages_3[5]

emails = lapply(seq_along(subset),
              function(i){
                website<-subset[i]
                contact1 <-contact_page1[i]
                contact2 <-contact_page2[i]
                contact3 <-contact_page3[i]
                
                email_domain <- pattens_subset[i]
                keyword <- str_remove(email_domain, "@")
                google_url <- paste0('https://www.google.com/search?q=', keyword, '%2C+email')
                x <- 1
                email <- list()
                
                candidates<-list(website, contact1, contact2, contact3, google_url)
                
                xpath = paste0("//*[contains(text(), '",email_domain,"')]")
                print(xpath)
                out <- tryCatch(
                  {
                    while(x <= length(candidates) && length(email) ==0){
                  
                      url <- candidates[[x]]
                      links <- get_email(url, xpath)
                      email <- unlist(links, recursive = TRUE, use.names = FALSE)
                      x <-  x+1
                    }
                    email <- email[!duplicated(email)]
                    # remove char(0)
                    email[lengths(email) == 0] <- ''
                    message(email)
                    return(email)
                  },
                  error=function(cond) {
                    message(cond)
                    # Choose a return value in case of error
                    return(NULL)
                  },
                  warning=function(cond) {
                    message(cond)
                    # Choose a return value in case of warning
                    return(NULL)
                  },
                  finally={
                    message(paste("Processed URL:", website))
                    message(paste("Progress:", i/length(urls)))
                  }
                )    
                return(out)
              })

df = tibble(
  s_name = names, 
  s_url = urls, 
  s_pattern = pattens,
  s_email=emails
)
df1 <- apply(df,2,as.character)
write.csv(df1, 'your/path')
