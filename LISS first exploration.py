#!/usr/bin/env python
# coding: utf-8

# # load and explore!

# In[1]:


import pandas as pd
LISS = pd.read_csv('LISS_example_input_data.csv',encoding='cp1252')
LISS.head()



# In[2]:


LISS.describe


# In[3]:


LIGT = pd.read_csv('LISS_example_groundtruth_data.csv',encoding='cp1252')
LIGT.head()


# In[4]:


LIGT.describe


# In[5]:


LIGT['new_child'].value_counts()


# ## some ideas on next steps to take
# 1. lets focus on the rows that actually have values for 'new_child' and then get rid of all of the columns that are fully NA.
# 2. select a bunch of meaningfull variables
# 3. scale the numerical ones
# 4. make ordinal and/or dummy the categorical ones
# 
# ---- their answer:
# These are the minimum steps that need to happen, in this order:
# 
# 1. Select features
# 2. Deal with missing data. The quickest way is to just drop all rows that have any missing value.
# 3. Preprocess the features: scaling for numerical values, one-hot encoding for categorical values.
# 4. Split the data in a train and test set.
# 5. Train the model and evaluate!

# In[6]:


## focus on the rows that we actually have outcomes for


# In[7]:


LISSBU = LISS.merge(LIGT, on='nomem_encr', how='left')


# In[8]:


LISSBU.describe


# In[9]:


# check counts
LISSBU['new_child'].value_counts()


# In[10]:


LISSBU = LISSBU.dropna(subset=['new_child'])


# In[11]:


LISSBU.describe


# In[12]:


LISSBU = LISSBU.dropna(axis=1, how='all') #ok, so this does not actually do an awfull lot...


# In[13]:


LISSBU.describe


# OK, so lets try to drop all where more than 50% is missing

# In[14]:


# First, compute the proportion of missing values in each column
missing_proportion = LISSBU.isnull().mean()

# Next, find columns where more than 50% of the values are missing
columns_to_drop = missing_proportion[missing_proportion > 0.95].index

# Finally, drop these columns from the DataFrame
LISSBU = LISSBU.drop(columns_to_drop, axis=1)
LISSBU.describe


# ## OK, so some manual selection, I would quite like as the variables:
# - age
# - race
# - sex - geslacht
# - native-country - herkomstgroep
# 
# #### family situation
# - marital status / relationship status - burgstat
# - does partner live in household? - partner
# - already children - aantalki --- can I use this as continues?
# 
# #### work domain
# - hours-per-week work
# - workclass
# - occupation
# 
# #### economic situation
# - education - oplzon  --- or: cat__oplmet2019?
# - capital-gain (last year?)
# - income - brutoink_f (imputed!)
# 
# 

# In[15]:


# lets make an array of the values I would like to use
varstouse = ['geslacht','herkomstgroep2019','burgstat2019','partner2019',"aantalki2019","oplzon2019","brutoink_f2019"]
varstouse


# In[16]:


columns_not_in_list = list(set(varstouse) - set(LISSBU.columns.tolist()))
columns_not_in_list


# In[17]:


LIFO = LISSBU[varstouse]


# In[18]:


LIFO.describe


# In[19]:


# OK so, lets start with some machine learning


# In[20]:


# lets first define the target
target = LISSBU["new_child"]
target.value_counts()


# In[21]:


from sklearn.preprocessing import OneHotEncoder
from sklearn.pipeline import make_pipeline
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_validate
from sklearn.preprocessing import StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer


# In[22]:


# split the numerical and categorical data
LIFOCAT = LIFO.drop(columns=['brutoink_f2019'])
LIFOCONT = LIFO[["brutoink_f2019"]]
print(LIFOCAT)
print(type(LIFOCAT))
print(LIFOCONT)
print(type(LIFOCONT))


# In[23]:


cat_encoder = OneHotEncoder(handle_unknown='ignore',sparse_output=False) # maybe also add min_fre
cont_scaler = StandardScaler()


# In[24]:


categorical_columns = LIFOCAT.columns.tolist()
numerical_columns = LIFOCONT.columns.tolist()
print(categorical_columns)
print(numerical_columns)


# In[25]:


cat_imputer = SimpleImputer(strategy='most_frequent')
cont_imputer = SimpleImputer(strategy='mean') # better is to do a regression based imputation here


# In[26]:


# Pipelines for each type of column
cat_pipeline = Pipeline([
    ('imputer', cat_imputer),
    ('encoder', cat_encoder)
])
cont_pipeline = Pipeline([
    ('imputer', cont_imputer),
    ('scaler', cont_scaler)
])

# Combine into a single preprocessor
preprocessor = ColumnTransformer([
    ('cat', cat_pipeline, categorical_columns),
    ('cont', cont_pipeline, numerical_columns)
])


# In[27]:


model = make_pipeline(preprocessor, LogisticRegression(max_iter=500))


# In[28]:


model


# In[34]:


cross_validate(model,LIFO,target,cv=5)


# #### some hyper parameter tuning here?

# In[ ]:





# ### let's try something more fancy machine learning wise

# In[38]:


from sklearn import svm
from sklearn.tree import DecisionTreeClassifier


# In[39]:


modeldt = make_pipeline(preprocessor, DecisionTreeClassifier()) #tree.DecisionTreeClassifier()


# In[40]:


modeldt


# In[33]:


cross_validate(modelsvm,LIFO,target,cv=5)


# In[ ]:





# In[ ]:




