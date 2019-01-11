import numpy as np
import scipy.signal as sig
import os
import datetime
import time


def main():
	motionFeatExt()

def rFFTpower(x):
	Fs = float(50)
	Ts = 1/Fs
	fall = np.fft.fftfreq(len(x),Ts)
	f = fall[:int(np.floor(len(fall)/2))]
	yall = np.abs(np.fft.fft(x))
	y = yall[:int(np.floor(len(yall)/2))]
	PY = (y**2)/(len(y)*Fs)
	PY1 = PY[np.where((f>0.1) & (f<=0.5))]
	PY1mean = np.mean(PY1)
	PY1max = np.amax(PY1)
	PY2 = PY[np.where((f>0.5) & (f<=3))]
	PY2mean = np.mean(PY2)
	PY2max = np.amax(PY2)
	PY3 = PY[np.where((f>3) & (f<=10))]
	PY3mean = np.mean(PY3)
	PY3max = np.amax(PY3)
	return PY1mean, PY1max, PY2mean, PY2max, PY3mean, PY3max
		
def rTeagerCompute(x):
    yy=np.zeros(len(x))
    temp_a = np.multiply(x[1:-1],x[1:-1]) - np.multiply(x[2:],x[:-2])
    yy[1:-1] = yy[1:-1]+temp_a[:]	
    yy[0] = temp_a[1]
    yy[-1] = temp_a[-1]
    y = np.abs(yy)
    return y

def motionFeatExt():

	debugMode = True

	FeatureList = ("timestamp_1,timestamp_2,"
	+"x_mean,x_median,x_max,x_var,x_rms,x_IQR,x_meanXrate,x_meanDiff,x_maxDiff,x_teager_mean,x_teager_std,"
	+"x_teager_max,x_fft_mean_0_1,x_fft_0_1_max,x_fft_mean_1_3,x_fft_1_3_max,x_fft_mean_3_10,x_fft_3_10_max,"
	+"y_mean,y_median,y_max,y_var,y_rms,y_IQR,y_meanXrate,y_meanDiff,y_maxDiff,y_teager_mean,y_teager_std,"
	+"y_teager_max,y_fft_mean_0_1,y_fft_0_1_max,y_fft_mean_1_3,y_fft_1_3_max,y_fft_mean_3_10,y_fft_3_10_max,"
	+"z_mean,z_median,z_max,z_var,z_rms,z_IQR,z_meanXrate,z_meanDiff,z_maxDiff,z_teager_mean,z_teager_std,"
	+"z_teager_max,z_fft_mean_0_1,z_fft_0_1_max,z_fft_mean_1_3,z_fft_1_3_max,z_fft_mean_3_10,z_fft_3_10_max,"
	+"mag_mean,mag_median,mag_max,mag_var,mag_rms,mag_IQR,mag_meanXrate,mag_meanDiff,mag_maxDiff,mag_teager_mean,mag_teager_std,"
	+"mag_teager_max,mag_fft_mean_0_1,mag_fft_0_1_max,mag_fft_mean_1_3,mag_fft_1_3_max,mag_fft_mean_3_10,mag_fft_3_10_max,"
	+"corr_xy,corr_xz,corr_yz"
	+"\n")

	x=[]
	y=[]
	z=[]

	rawTime=[]
	rawX=[]
	rawY=[]
	rawZ=[]

	windowSize = 3000 #50Hz*60sec = 1min
	stepSize = windowSize/2

	startReadLine = 1 #line0 = header, line1 = startline on the rawPebble file
	currLine = startReadLine #init current read line as the start line

	tempFolder = "/media/card/Relay_station10009/"
	
	rawFolder = "rawPebble/"
	featureFolder = "PebbleFeature/"


	if not os.path.exists(tempFolder + featureFolder): #for Pebble data that's done with featExt
		os.mkdir(tempFolder + featureFolder)

	files = os.walk(tempFolder + rawFolder).next()[2] #BASE_PATH = /media/card/
	files.sort() #previous file first

	for i in range(len(files)):
		#Generate destination file
		#Convert Epoch time -> readable Time 
		dstFileTime = files[i].split('_')
		dstFileTime = dstFileTime[2].split('.')
		dstFileTime = datetime.datetime.fromtimestamp(int(dstFileTime[0])/1000)
		#dstFileTime = dstFileTime - datetime.timedelta(hours=5) #ET time
		dstFileTime = dstFileTime.strftime('%y-%m-%d_%H-%M-%S')

		PebbleFeatureFileName = tempFolder+featureFolder+"PebbleFeature{0}.txt".format(dstFileTime)
		#check if the PebbleFeature has already been created 
		# if not os.path.exists(BASE_PATH + pebbleFolder + "/" +files[0]):
		# if not os.path.exists(PebbleFeatureFileName):
		with open(PebbleFeatureFileName, "w") as PebbleFeatureFile:
			# PebbleFeatureFile.write("timestamp_1,timestamp_2,x_max,x_min,x_mean,x_std,x_fft_mean,x_fft_0_1_max,x_fft_mean_0_1,x_fft_1_3_max,x_fft_mean_1_3,x_fft_3_10_max,x_fft_mean_3_10,x_teager_mean,x_teager_max,y_max,y_min,y_mean,y_std,y_fft_mean,y_fft_0_1_max,y_fft_mean_0_1,y_fft_1_3_max,y_fft_mean_1_3,y_fft_3_10_max,y_fft_mean_3_10,y_teager_mean,y_teager_max,z_max,z_min,z_mean,z_std,z_fft_mean,z_fft_0_1_max,z_fft_mean_0_1,z_fft_1_3_max,z_fft_mean_1_3,z_fft_3_10_max,z_fft_mean_3_10,z_teager_mean,z_teager_max")
			PebbleFeatureFile.write(FeatureList)

		f = open(tempFolder + rawFolder + "/" + files[i], "r") 
		if debugMode: print "reading from " + files[i]
		rawlineCount = 0
		for numLines in f.xreadlines(  ): rawlineCount += 1 # read #of lines
		f.close()
		currLine = startReadLine #init current read line as the start line

		if rawlineCount > currLine:			

			if debugMode: print "length of rawX,Y,Z = " + str(len(rawX))

			with open(tempFolder + rawFolder + "/" + files[i], "r") as rawPebble:
				# for i in range(currLine, rawlineCount):

				rawPebbleData = rawPebble.readlines()[currLine:rawlineCount]

				for j in range(len(rawPebbleData)): #rawPebbleData[i] = z,y,x,time, rawPebbleData = [{z,y,x,time}; {z,y,x,time}...]

					num = rawPebbleData[j].split(',')
					if len(num) >= 4:
						rawZ.append(float(int(num[0])))
						rawY.append(float(int(num[1])))
						rawX.append(float(int(num[2])))
						rawTime.append(int(num[3])) 
						# rawTime.append(int(num[4])) #for P2D4
						# print num[0] +" "+num[1] +" "+ num[2] +" "+ num[3]

				currLine = rawlineCount
				if debugMode: print "currLine = " +str(currLine)

		while ((len(rawX)>windowSize) and (len(rawY)>windowSize) and (len(rawZ)>windowSize)) :
			#if debugMode: print "Feature Extracting.."
			#if debugMode: print "data length = " + str(len(rawX))
			
			lower_lim = 0 #some feature required data[lower_lim-1]
			upper_lim = windowSize-1 #3000
			
			clippingValue=4000.0

			timestamp_1 = rawTime[lower_lim]
			timestamp_2 = rawTime[upper_lim]

			#for pre-processing
			rx = np.maximum(np.minimum(rawX[:windowSize],clippingValue),(-1)*clippingValue) 
			ry = np.maximum(np.minimum(rawY[:windowSize],clippingValue),(-1)*clippingValue)
			rz = np.maximum(np.minimum(rawZ[:windowSize],clippingValue),(-1)*clippingValue)
			#if debugMode: print str(rx[0:30])+'\n'+str(ry[0:30])+'\n'+str(rz[0:30]) 
			
			timeDiff = timestamp_2 - timestamp_1
			
			rxindices = np.where(np.abs(rx[:])==clippingValue)
			ryindices = np.where(np.abs(ry[:])==clippingValue)
			rzindices = np.where(np.abs(rz[:])==clippingValue)
			if debugMode: 
			    print str(np.size(rxindices))+';'+str(np.size(ryindices))+';'+ \
				str(np.size(rzindices))+';time:'+str(timeDiff)
			
			if (np.size(rxindices)>2000 or np.size(rxindices)>2000 or \
				np.size(rxindices)>2000 or timeDiff>200000 or timeDiff<=0):
				if debugMode: print "flag: false"
				del rawX[0:stepSize]
				del rawY[0:stepSize]
				del rawZ[0:stepSize]
				del rawTime[0:stepSize]
				continue
			
			maskx = np.ones(rx.shape,dtype=bool)
			maskx[rxindices] = 0
			rx[rxindices] = np.mean(rx[maskx])
			masky = np.ones(ry.shape,dtype=bool)
			masky[ryindices] = 0
			ry[ryindices] = np.mean(ry[masky])
			maskz = np.ones(rz.shape,dtype=bool)
			maskz[rzindices] = 0
			rz[rzindices] = np.mean(rz[maskz])
			
			
			
			mx = rx[:] #sig.medfilt(rx[:],5)
			my = ry[:] #sig.medfilt(ry[:],5)
			mz = rz[:] #sig.medfilt(rz[:],5)
			#if debugMode: print 'median:\n'+str(mx[0:30])+'\n'+str(my[0:30])+'\n'+str(mz[0:30]) 
		
			x = ((mx[:]+4000.0)/8000.0) * 100.0
			y = ((my[:]+4000.0)/8000.0) * 100.0
			z = ((mz[:]+4000.0)/8000.0) * 100.0
			#if debugMode: print str(x[0:30])+'\n'+str(y[0:30])+'\n'+str(z[0:30]) 
			#if debugMode: print np.diff(rawTime[0:3000])
		
			# x,y,z = motionPreProcessing(x,y,z,rawTime[0:3050])
			mag = np.sqrt(np.square(x[:]) + np.square(y[:]) + np.square(z[:]))


			##### frequency #####
			x_fft_mean_0_1,x_fft_0_1_max,x_fft_mean_1_3,x_fft_1_3_max,x_fft_mean_3_10,x_fft_3_10_max = rFFTpower(x[lower_lim:upper_lim])
			y_fft_mean_0_1,y_fft_0_1_max,y_fft_mean_1_3,y_fft_1_3_max,y_fft_mean_3_10,y_fft_3_10_max = rFFTpower(y[lower_lim:upper_lim])
			z_fft_mean_0_1,z_fft_0_1_max,z_fft_mean_1_3,z_fft_1_3_max,z_fft_mean_3_10,z_fft_3_10_max = rFFTpower(z[lower_lim:upper_lim])
			mag_fft_mean_0_1,mag_fft_0_1_max,mag_fft_mean_1_3,mag_fft_1_3_max,mag_fft_mean_3_10,mag_fft_3_10_max = rFFTpower(mag[lower_lim:upper_lim])
			#####

			##### teagers #####
			x_teager = rTeagerCompute(x[lower_lim:upper_lim])
			y_teager = rTeagerCompute(y[lower_lim:upper_lim])
			z_teager = rTeagerCompute(z[lower_lim:upper_lim])
			mag_teager = rTeagerCompute(mag[lower_lim:upper_lim])
			#if debugMode: print 'Teager:\n'+str(x_teager[0:30])+'\n'+str(y_teager[0:30])+'\n'+str(z_teager[0:30]) 

			x_teager_max = np.amax(x_teager[:])
			x_teager_mean = np.mean(x_teager[:])
			y_teager_max = np.amax(y_teager[:])
			y_teager_mean = np.mean(y_teager[:])    
			z_teager_max = np.amax(z_teager[:])
			z_teager_mean = np.mean(z_teager[:])
			mag_teager_max = np.amax(mag_teager[:])
			mag_teager_mean = np.mean(mag_teager[:])
			
			x_teager_std = np.std(x_teager[:])
			y_teager_std = np.std(y_teager[:])
			z_teager_std = np.std(z_teager[:])
			mag_teager_std = np.std(mag_teager[:])
			#####

			##### x features #####
			x_max = np.amax(x[lower_lim:upper_lim])
			x_mean = np.mean(x[lower_lim:upper_lim])
			x_median = np.median(x[lower_lim:upper_lim])
			x_var = np.var(x[lower_lim:upper_lim])
			x_rms = np.sqrt(np.mean(np.square(x[lower_lim:upper_lim])))
			x_IQR = np.subtract(*np.percentile(x[lower_lim:upper_lim], [75, 25]))
			#Mean x Rate
			xArray = np.array(x[lower_lim:upper_lim])
			xArrayZ = xArray[:] - x_mean
			x_meanXrate = np.sum(np.sign(np.multiply(xArrayZ[1:],xArrayZ[:-1]))!=1)
			x_meanDiff = np.mean(np.diff(x[lower_lim:upper_lim]))
			x_maxDiff = np.amax(np.diff(x[lower_lim:upper_lim]))

			##### y features #####
			y_max = np.amax(y[lower_lim:upper_lim])
			y_mean = np.mean(y[lower_lim:upper_lim])
			y_median = np.median(y[lower_lim:upper_lim])
			y_var = np.var(y[lower_lim:upper_lim])
			y_rms = np.sqrt(np.mean(np.square(y[lower_lim:upper_lim])))
			y_IQR = np.subtract(*np.percentile(y[lower_lim:upper_lim], [75, 25]))
			#Mean x Rate
			yArray = np.array(y[lower_lim:upper_lim])
			yArrayZ = yArray[:] - y_mean
			y_meanXrate = np.sum(np.sign(np.multiply(yArrayZ[1:],yArrayZ[:-1]))!=1)
			y_meanDiff = np.mean(np.diff(y[lower_lim:upper_lim]))
			y_maxDiff = np.amax(np.diff(y[lower_lim:upper_lim]))

			##### z features #####
			z_max = np.amax(z[lower_lim:upper_lim])
			z_mean = np.mean(z[lower_lim:upper_lim])
			z_median = np.median(z[lower_lim:upper_lim])
			z_var = np.var(z[lower_lim:upper_lim])
			z_rms = np.sqrt(np.mean(np.square(z[lower_lim:upper_lim])))
			z_IQR = np.subtract(*np.percentile(z[lower_lim:upper_lim], [75, 25]))
			#Mean x Rate
			zArray = np.array(z[lower_lim:upper_lim])
			zArrayZ = zArray[:] - z_mean
			z_meanXrate = np.sum(np.sign(np.multiply(zArrayZ[1:],zArrayZ[:-1]))!=1)
			z_meanDiff = np.mean(np.diff(z[lower_lim:upper_lim]))
			z_maxDiff = np.amax(np.diff(z[lower_lim:upper_lim]))

			##### mag features #####
			mag_max = np.amax(mag[lower_lim:upper_lim])
			mag_mean = np.mean(mag[lower_lim:upper_lim])
			mag_median = np.median(mag[lower_lim:upper_lim])
			mag_var = np.var(mag[lower_lim:upper_lim])
			mag_rms = np.sqrt(np.mean(np.square(mag[lower_lim:upper_lim])))
			mag_IQR = np.subtract(*np.percentile(mag[lower_lim:upper_lim], [75, 25]))
			#Mean x Rate
			magArray = np.array(mag[lower_lim:upper_lim])
			magArrayZ = magArray[:] - mag_mean
			mag_meanXrate = np.sum(np.sign(np.multiply(magArrayZ[1:],magArrayZ[:-1]))!=1)
			mag_meanDiff = np.mean(np.diff(mag[lower_lim:upper_lim]))
			mag_maxDiff = np.amax(np.diff(mag[lower_lim:upper_lim]))

			#corrcoef
			corr_xy = np.corrcoef(x[lower_lim:upper_lim],y[lower_lim:upper_lim])[0,1]
			corr_xz = np.corrcoef(z[lower_lim:upper_lim],x[lower_lim:upper_lim])[0,1]
			corr_yz = np.corrcoef(y[lower_lim:upper_lim],z[lower_lim:upper_lim])[0,1]


			with open(PebbleFeatureFileName, "a") as PebbleFeatureFile:
				PebbleFeatureFile.write(str(timestamp_1) + ", " + str(timestamp_2) 
					+ ", " + str(x_mean) + ", " + str(x_median) + ", " + str(x_max) 
					+ ", " + str(x_var) + ", " + str(x_rms) + ", " + str(x_IQR) 
					+ ", " + str(x_meanXrate) + ", " + str(x_meanDiff) + ", " + str(x_maxDiff)  
					+ ", " + str(x_teager_mean) + ", " + str(x_teager_std) + ", " + str(x_teager_max)
					+ ", " + str(x_fft_mean_0_1) + ", " + str(x_fft_0_1_max) + ", " + str(x_fft_mean_1_3)
					+ ", " + str(x_fft_1_3_max) + ", " + str(x_fft_mean_3_10) + ", " + str(x_fft_3_10_max)  
					+ ", " + str(y_mean) + ", " + str(y_median) + ", " + str(y_max) 
					+ ", " + str(y_var) + ", " + str(y_rms) + ", " + str(y_IQR) 
					+ ", " + str(y_meanXrate) + ", " + str(y_meanDiff) + ", " + str(y_maxDiff)  
					+ ", " + str(y_teager_mean) + ", " + str(y_teager_std) + ", " + str(y_teager_max)
					+ ", " + str(y_fft_mean_0_1) + ", " + str(y_fft_0_1_max) + ", " + str(y_fft_mean_1_3)
					+ ", " + str(y_fft_1_3_max) + ", " + str(y_fft_mean_3_10) + ", " + str(y_fft_3_10_max) 
					+ ", " + str(z_mean) + ", " + str(z_median) + ", " + str(z_max) 
					+ ", " + str(z_var) + ", " + str(z_rms) + ", " + str(z_IQR) 
					+ ", " + str(z_meanXrate) + ", " + str(z_meanDiff) + ", " + str(z_maxDiff)  
					+ ", " + str(z_teager_mean) + ", " + str(z_teager_std) + ", " + str(z_teager_max)
					+ ", " + str(z_fft_mean_0_1) + ", " + str(z_fft_0_1_max) + ", " + str(z_fft_mean_1_3)
					+ ", " + str(z_fft_1_3_max) + ", " + str(z_fft_mean_3_10) + ", " + str(z_fft_3_10_max) 
					+ ", " + str(mag_mean) + ", " + str(mag_median) + ", " + str(mag_max) 
					+ ", " + str(mag_var) + ", " + str(mag_rms) + ", " + str(mag_IQR) 
					+ ", " + str(mag_meanXrate) + ", " + str(mag_meanDiff) + ", " + str(mag_maxDiff)  
					+ ", " + str(mag_teager_mean) + ", " + str(mag_teager_std) + ", " + str(mag_teager_max)
					+ ", " + str(mag_fft_mean_0_1) + ", " + str(mag_fft_0_1_max) + ", " + str(mag_fft_mean_1_3)
					+ ", " + str(mag_fft_1_3_max) + ", " + str(mag_fft_mean_3_10) + ", " + str(mag_fft_3_10_max) 
					+ ", " + str(corr_xy) + ", " + str(corr_xz) + ", " + str(corr_yz)
					+ "\n ")

			del rawX[0:stepSize]
			del rawY[0:stepSize]
			del rawZ[0:stepSize]
			del rawTime[0:stepSize]

	# if debugMode: print str(rawTime[-1])
# do stuff in main() -- for 'after declare' function
if __name__ == '__main__':
    main()