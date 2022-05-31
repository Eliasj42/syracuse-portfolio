import nltk
import os
import collections
import numpy as np
import tensorflow as tf
from nltk.tokenize import word_tokenize, sent_tokenize
import random
from tensorflow.keras.utils import to_categorical
from sklearn.naive_bayes import GaussianNB
stopwords = nltk.corpus.stopwords.words('english')
from sklearn.metrics import f1_score, precision_score, recall_score, confusion_matrix, accuracy_score

#### CHANGE PARAMETERS HERE ###
REMOVE_STOPWORDS = False
USE_WORD_COUNTS = True
USE_PERCENT_NEW_WORDS = False

# Read in the data
def read_spam_file(fname, isspam, clean = REMOVE_STOPWORDS):
    try:
        f_ = open(fname, 'r')
        email = f_.read()
        f_.close()
    except:
        return None
    
    tokens = word_tokenize(email)
    tokens = [token.lower() for token in tokens]
    if clean:
        tokens = [token for token in tokens if token.isalpha()]
        tokens = [token for token in tokens if token not in stopwords]
    
    return (tokens, isspam)

# Create a dataset of all emails from both spam and ham folders
def create_all_emails():
    ham_emails = [read_spam_file('FinalProjectData/EmailSpamCorpora/corpus/ham/' + fname, False) 
              for fname in os.listdir('FinalProjectData/EmailSpamCorpora/corpus/ham/')]
    ham_emails = [x for x in ham_emails if x is not None]
    spam_emails = [read_spam_file('FinalProjectData/EmailSpamCorpora/corpus/spam/' + fname, True) 
               for fname in os.listdir('FinalProjectData/EmailSpamCorpora/corpus/spam/')]
    spam_emails = [x for x in spam_emails if x is not None]
    all_emails = ham_emails + spam_emails
    random.shuffle(all_emails)
    return all_emails

all_emails = create_all_emails()

all_words_list = [word for (sent,cat) in all_emails for word in sent]
all_words = nltk.FreqDist(all_words_list)
word_items = all_words.most_common(3000)
word_features = [word for (word,count) in word_items]

def percent_new_words(email, word_features):
    # Calculated the percentage of words not in the top 3000
    email_words = set(email)
    not_in = 0
    total = 0
    for word in word_features:
        total += 1
        if not word in email_words:
            not_in += 1
    return not_in / total

# Turn each email into a feature set
def email_features(email, use_counts, word_features = word_features, new_feature1 = False):
    email_words = set(email)
    features = {}
    for word in word_features:
        if not use_counts: features['V_{}'.format(word)] = int(word in email_words)
        if use_counts: features['V_{}'.format(word)] = email.count(word)
    result = list(features.values())
    if new_feature1:
        result += [percent_new_words(email, word_features)]
    return np.asarray(result)

X = [email_features(email, 
                    USE_WORD_COUNTS, 
                    new_feature1 = USE_PERCENT_NEW_WORDS) for (email, _) in all_emails]
Y = [int(spam) for (_, spam) in all_emails]

assert(len(X) == len(Y))

cutoff = int(len(X) * 0.9)

Xtrain = np.asarray(X[:cutoff])
Xtest = np.asarray(X[cutoff:])
Ytrain = np.asarray(Y[:cutoff])
Ytest = np.asarray(Y[cutoff:])

# Create folds for cross validation
fold_size = int(len(X)/10)
Xfolds = []
Yfolds = []
for i in range(10):
    if i == 0:
        Xfolds.append(X[:fold_size])
        Yfolds.append(Y[:fold_size])
    elif i == 9:
        Xfolds.append(X[9 * fold_size:])
        Yfolds.append(Y[9 * fold_size:])
    else:
        Xfolds.append(X[i * fold_size:(i + 1) * fold_size])
        Yfolds.append(Y[i * fold_size:(i + 1) * fold_size]) 
        
# Run Naive Bayes with Cross validation
def Naive_Bayes_with_CV(Xfolds, Yfolds):
    gnb = GaussianNB()
    acc = []
    prec = []
    rec = []
    fstat = []
    for i in range(len(Xfolds)):
        xtrain = []
        ytrain = []
        xtest = Xfolds[i]
        ytest = Yfolds[i]
        for j in range(len(Xfolds)):
            if j != i:
                xtrain += Xfolds[j]
                ytrain += Yfolds[j]
        xtrain = np.asarray(xtrain)
        ytrain = np.asarray(ytrain)
        xtest = np.asarray(xtest)
        ytest = np.asarray(ytest)
        y_pred = gnb.fit(xtrain, ytrain).predict(xtest)
        tp = 0
        fp = 0
        tn = 0
        fn = 0
        n = 0
        for k in range(len(y_pred)):
            if y_pred[k] == 1 and ytest[k] == 1: tp += 1
            elif y_pred[k] == 0 and ytest[k] == 0: tn += 1
            elif y_pred[k] == 0 and ytest[k] == 1: fn += 1
            elif y_pred[k] == 1 and ytest[k] == 0: fp += 1
            n += 1
        acc.append((tn + tp) / n)
        prec.append(tp / (tp + fp))
        rec.append(tp / (tp + fn))
        fstat.append(2 * (((tp / (tp + fp)) * (tp / (tp + fn)))/((tp / (tp + fp)) + (tp / (tp + fn)))))
    return np.asarray(acc), np.asarray(prec), np.asarray(rec), np.asarray(fstat)

# Print Accuracy Statistics
accuracy, precision, recall, fmeasure = Naive_Bayes_with_CV(Xfolds, Yfolds)
print('Accuracy:', np.mean(accuracy))
print('Precision:', np.mean(precision))
print('Recall:', np.mean(recall))
print('F-measure:', np.mean(fmeasure))

# Define a NN model
model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(3000, activation = 'relu'))
model.add(tf.keras.layers.Dropout(0.75))
model.add(tf.keras.layers.Dense(1000, activation = 'relu'))
model.add(tf.keras.layers.Dropout(0.25))
model.add(tf.keras.layers.Dense(250, activation = 'relu'))
model.add(tf.keras.layers.Dense(1000, activation = 'relu'))
model.add(tf.keras.layers.Dense(2, activation = 'softmax'))

model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])
model.fit(Xtrain, to_categorical(Ytrain), epochs = 25, batch_size = 20, validation_split = 0.1)

# print Accuracy measures
Ypred = model.predict(Xtest)
Ypred = np.argmax(Ypred, axis = 1)
Ytest = Ytest
print('Accuracy:', accuracy_score(Ytest, Ypred))
print('Precision:',precision_score(Ytest, Ypred))
print('Recall:',recall_score(Ytest, Ypred))
print('F-Measure:',f1_score(Ytest, Ypred))