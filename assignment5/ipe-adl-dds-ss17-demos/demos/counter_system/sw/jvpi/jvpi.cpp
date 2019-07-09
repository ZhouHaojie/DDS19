#include <limits.h> /* PATH_MAX */

#include  <iverilog/vpi_user.h>

#include <jni.h>       /* where everything is defined */

#include <vector>
#include <dirent.h>
#include <string>
#include <ostream>
#include <sstream>
#include <fstream>
#include <iterator>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <cstring>

static jboolean jniFalseVal = JNI_FALSE;
static jboolean jniTrueVal = JNI_TRUE;
JavaVM * jvm;
//JNIEnv *env;
jclass vpiRunObj;

typedef struct cbPair {
	jobject obj;
	jclass cl;
	JNIEnv *env;
} cbPair;

cbPair * p;

// VPI Interface
//---------------------
static int valueChanged(struct t_cb_data * cb_data) {

	//cbPair * p = (cbPair *) cb_data->user_data;
	//jobject callback = p->obj;
	//jclass cbClass = p->cl;

	JNIEnv * env;
	int res = jvm->AttachCurrentThread((void **) &env, NULL);

	if (res == JNI_OK) {

		//jclass cbClass  = env->GetObjectClass(callback);
		jclass cbClass = env->FindClass("vpi/VPIInterface");

		jmethodID changeMethod = env->GetStaticMethodID(cbClass,
				"triggerChanged", "(Ljava/lang/String;Ljava/lang/String;J)V");
		/*if(changeMethod==NULL) {
		 std::cout << "Could not find changed method"
		 }*/
		jstring nameStr = env->NewStringUTF((char*) cb_data->user_data);
		jstring valStr = env->NewStringUTF(cb_data->value->value.str);

		jlong time = cb_data->time->high;

		time = (time << 32) | (cb_data->time->low / 100);


		//std::cout << "Value Changed!, CB is for "<< cb_data->user_data <<", value="<< cb_data->value->value.str << ",time=" << time<<  std::endl;

		//jlong time = (cb_data->time->high << 32) | cb_data->time->low;
		env->CallStaticVoidMethod(cbClass, changeMethod, nameStr, valStr, time);

		jvm->DetachCurrentThread();

		/*jstring valStr = env->NewString((const jchar*)cb_data->value->value.str,(jsize)strlen(cb_data->value->value.str));
		 env->CallVoidMethod(callback,changeMethod,valStr);*/

	} else {
		std::cout << "Cannot attach to VM" << std::endl;
	}

	return 0;
}
void registerVPIChange(JNIEnv *env, jobject obj, jstring name) {

	t_cb_data * changeCallBack = new t_cb_data();
	changeCallBack->obj = NULL;
	changeCallBack->cb_rtn = valueChanged;
	changeCallBack->reason = cbValueChange;

	changeCallBack->value = new s_vpi_value;
	changeCallBack->value->format = vpiDecStrVal;

	changeCallBack->time = new s_vpi_time;
	changeCallBack->time->type = vpiSimTime;

	//env->NewGlobalRef(callback);
	//jclass cbClass  = env->GetObjectClass(callback);
	//env->NewGlobalRef(cbClass);

	/* p = new cbPair;
	 p->obj = callback;
	 p->cl = cbClass;
	 p->env = env;*/

	changeCallBack->user_data = (PLI_BYTE8*) env->GetStringUTFChars(name,
			&jniTrueVal);

	vpiHandle net = vpi_handle_by_name(
			(char*) env->GetStringUTFChars(name, &jniFalseVal), NULL);
	changeCallBack->obj = net;

	/*jmethodID changeMethod = env->GetMethodID(cbClass,"changed","(Ljava/lang/String;)V");
	 jstring valStr = env->NewStringUTF("10");
	 env->CallVoidMethod(callback,changeMethod,valStr);*/

	vpi_register_cb(changeCallBack);

	std::cout << "Watching register: CB=, name="
			<< env->GetStringUTFChars(name, &jniFalseVal) << std::endl;

}

typedef struct updateVPIData {

	std::string name;
	int value;
	int index;

} updateVPIData;
int writeVPIValueCb(struct t_cb_data * cb_data) {

	updateVPIData * userData = (updateVPIData *) cb_data->user_data;

	std::cout << "Next sim time: " << userData->name << "=" << userData->value
			<< "index is=" << userData->index << std::endl;

	//-- Get Net
	vpiHandle net = vpi_handle_by_name((char*) userData->name.c_str(), NULL);



	if(net==0) {
		std::cout << "Cannot Write VPI Value, net not found" << std::endl;
	} else {

		//-- Prepare value
		t_vpi_value value;
		value.format = vpiIntVal;
		value.value.integer = userData->value;



		//-- Use bit handle ?
		//-- handle to memory location is not supported by Icarus, so do it ourselves
		if (userData->index>=0) {

			vpi_get_value(net,&value);

			//-- Clear bit
			if ( userData->value==0) {
				value.value.integer  &= ~(1 << userData->index);

			}
			//-- Set bit
			else {
				value.value.integer |= 1 << userData->index;
			}

		}

		//-- Put
		vpi_put_value(net, &value, NULL, vpiNoDelay);
	}



	free(userData);
	return 0;
}

void writeVPIValue(JNIEnv *env, jobject obj, jstring name, jint v,jint index) {

	const char * vpiname = env->GetStringUTFChars(name, &jniTrueVal);

	//vpi_mode_flag = VPI_MODE_RWSYNC;

	std::cout << "Writing VPI Value to: " << vpiname << "=" << v << " -> " <<  std::endl;

	//-- Get Time
	/*t_vpi_time time;
	 time.type = vpiSimTime;
	 vpi_get_time(NULL, &time);*/

	// CallBack
	///-------------------------
	updateVPIData * userData = new updateVPIData;
	userData->name = std::string(vpiname);
	userData->value = v;
	userData->index = index;

	t_cb_data * putValueCallback = new t_cb_data();
	putValueCallback->obj = NULL;
	putValueCallback->cb_rtn = writeVPIValueCb;
	putValueCallback->reason = cbNextSimTime;
	putValueCallback->user_data = (PLI_BYTE8*) userData;

	vpi_register_cb(putValueCallback);

	//cbNextSimTime

}

#include <pthread.h>    /* required for pthreads */
#include <semaphore.h>  /* required for semaphores */

typedef struct readVPIData {

	std::string name;
	int value;
	char  valueStr[64];
	int index;
	sem_t readDone;
	int valType;

} readVPIData;
int readVPIValueCb(struct t_cb_data * cb_data) {

	readVPIData * userData = (readVPIData *) cb_data->user_data;

	//std::cout << "Read Value CB " <<  userData->name  <<  std::endl;

	//-- Get Net
	vpiHandle net = vpi_handle_by_name((char*) userData->name.c_str(), NULL);
	if(net==0) {
		std::cout << "Cannot Read VPI Value, net not found" << std::endl;
		userData->value = 0;

	} else {
		//-- Prepare value
		t_vpi_value value;
		value.format = userData->valType;


		//-- Read
		vpi_get_value(net, &value);

		if (value.format==vpiIntVal) {
			userData->value = value.value.integer;
		} else {
			std::strcpy (userData->valueStr,value.value.str);
		}


		//std::cout << "Done read: " << userData->value << std::endl;
		//userData->value = 0;

		//-- Notify
		sem_post(&(userData->readDone));

		//-- Return
		/*if (index>=0) {
			return ((value.value.integer>>index)&0x1);
		} else {
			return value.value.integer;
		}*/


	}


	return 0;

}


jint readVPIValueInt(JNIEnv *env, jobject obj, jstring name,jint index) {

	//-- Get Net
	const char * vpiname = env->GetStringUTFChars(name, &jniTrueVal);


	// CallBack
	///-------------------------
	readVPIData * userData = new readVPIData;
	userData->name = std::string(vpiname);
	userData->index = index;
	userData->valType = vpiIntVal;
	sem_init(&(userData->readDone), 0, 0);

	t_cb_data * readValueCallback = new t_cb_data();
	readValueCallback->obj = NULL;
	readValueCallback->cb_rtn = readVPIValueCb;
	readValueCallback->reason = cbNextSimTime;
	readValueCallback->user_data = (PLI_BYTE8*) userData;

	vpi_register_cb(readValueCallback);

	//-- Wait for done
	//std::cout << "Wait for done" << std::endl;
	sem_wait(&(userData->readDone));

	//std::cout << "Read done for index " << index << "-> " << userData->value << std::endl;
	int val = userData->value;
	free(userData);
	if (index>=0) {
		return ((val>>index)&0x1);
	} else {
		return val;
	}

}

jstring  readVPIValueBinStr(JNIEnv *env, jobject obj, jstring name,jint index) {

	//-- Get Net
	const char * vpiname = env->GetStringUTFChars(name, &jniTrueVal);


	// CallBack
	///-------------------------
	readVPIData * userData = new readVPIData;
	userData->name = std::string(vpiname);
	userData->index = index;
	userData->valType = vpiBinStrVal;
	sem_init(&(userData->readDone), 0, 0);

	t_cb_data * readValueCallback = new t_cb_data();
	readValueCallback->obj = NULL;
	readValueCallback->cb_rtn = readVPIValueCb;
	readValueCallback->reason = cbNextSimTime;
	readValueCallback->user_data = (PLI_BYTE8*) userData;

	vpi_register_cb(readValueCallback);

	//-- Wait for done
	//std::cout << "Wait for done" << std::endl;
	sem_wait(&(userData->readDone));

	//std::cout << "Read done for index " << index << "-> " << userData->value << std::endl;
	jstring val = env->NewStringUTF(userData->valueStr);
	free(userData);
	return val;

}
static JNINativeMethod registerVPIChangeDef = { "registerVPIOnChange",
		"(Ljava/lang/String;)V", (void*) registerVPIChange };

static JNINativeMethod writeVPIValueDef = { "writeVPIValue",
		"(Ljava/lang/String;II)V", (void*) writeVPIValue };

static JNINativeMethod readVPIValueIntDef = { "readVPIAsInt",
		"(Ljava/lang/String;I)I", (void*) readVPIValueInt };
static JNINativeMethod readVPIValueBinStrDef = { "readVPIAsBinStr",
		"(Ljava/lang/String;)Ljava/lang/String;", (void*) readVPIValueBinStr };



// Startup
//-------------------------
static t_cb_data startupCallBackDef;
static s_vpi_time startupCallBackTime = { vpiSimTime };
static s_vpi_value startupCallBackValue = { vpiSuppressVal };

static int startJava(struct t_cb_data *) {

	vpi_printf("Hello, World 2 JVM!\n");

	// Dependencies using classpath
	//------------------
	std::ifstream ifs("classpath.cp");
	std::string cpContent( (std::istreambuf_iterator<char>(ifs) ),
	                       (std::istreambuf_iterator<char>()    ) );

	// Main Class
	//----------------
	std::ifstream mifs("main.txt");
	std::string mainName( (std::istreambuf_iterator<char>(mifs) ),
		                       (std::istreambuf_iterator<char>()    ) );

	// Create JVM
	//--------------------
	JNIEnv *env;
	JavaVMInitArgs vm_args;
	JavaVMOption* options = new JavaVMOption[2];

	// Java classpath using local file

/*	options[0].optionString =
			"-Djava.class.path=C:\\Users\\leysr\\git\\adl\\lectures\\dds\\current\\app\\target\\classes;C:\\Users\\leysr\\git\\adl\\lectures\\dds\\current\\app\\target\\test-classes;C:\\Users\\leysr\\git\\main\\eda\\hdl\\h2dl\\master\\indesign\\target\\classes;C:\\Users\\leysr\\git\\main\\eda\\hdl\\h2dl\\master\\indesign\\target\\test-classes;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\tcl\\tcl-interface\\0.0.1-SNAPSHOT\\tcl-interface-0.0.1-SNAPSHOT.jar;C:\\Users\\leysr\\.m2\\repository\\com\\nativelibs4java\\bridj-odfi\\0.7.1.odfi\\bridj-odfi-0.7.1.odfi.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\android\\tools\\dx\\1.7\\dx-1.7.jar;C:\\Users\\leysr\\git\\main\\indesign\\ide\\dev\\ide-core\\target\\classes;C:\\Users\\leysr\\git\\main\\indesign\\ide\\dev\\ide-core\\target\\test-classes;C:\\Users\\leysr\\git\\main\\indesign\\core\\master\\indesign-core\\target\\classes;C:\\Users\\leysr\\git\\main\\indesign\\core\\master\\indesign-core\\target\\test-classes;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-util\\1.1.0\\aether-util-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-api\\1.1.0\\aether-api-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-transport-file\\1.1.0\\aether-transport-file-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-spi\\1.1.0\\aether-spi-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-transport-http\\1.1.0\\aether-transport-http-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\httpcomponents\\httpclient\\4.3.5\\httpclient-4.3.5.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\httpcomponents\\httpcore\\4.3.2\\httpcore-4.3.2.jar;C:\\Users\\leysr\\.m2\\repository\\commons-codec\\commons-codec\\1.6\\commons-codec-1.6.jar;C:\\Users\\leysr\\.m2\\repository\\org\\slf4j\\jcl-over-slf4j\\1.6.2\\jcl-over-slf4j-1.6.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-connector-basic\\1.1.0\\aether-connector-basic-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-embedder\\3.3.9\\maven-embedder-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-settings\\3.3.9\\maven-settings-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-core\\3.3.9\\maven-core-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-model\\3.3.9\\maven-model-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-settings-builder\\3.3.9\\maven-settings-builder-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-repository-metadata\\3.3.9\\maven-repository-metadata-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-artifact\\3.3.9\\maven-artifact-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-aether-provider\\3.3.9\\maven-aether-provider-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-impl\\1.0.2.v20150114\\aether-impl-1.0.2.v20150114.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\inject\\guice\\4.0\\guice-4.0-no_aop.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\inject\\javax.inject\\1\\javax.inject-1.jar;C:\\Users\\leysr\\.m2\\repository\\aopalliance\\aopalliance\\1.0\\aopalliance-1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-interpolation\\1.21\\plexus-interpolation-1.21.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-plugin-api\\3.3.9\\maven-plugin-api-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-model-builder\\3.3.9\\maven-model-builder-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-builder-support\\3.3.9\\maven-builder-support-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\guava\\guava\\18.0\\guava-18.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-compat\\3.3.9\\maven-compat-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\wagon\\wagon-provider-api\\2.10\\wagon-provider-api-2.10.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-utils\\3.0.22\\plexus-utils-3.0.22.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-classworlds\\2.5.2\\plexus-classworlds-2.5.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\sisu\\org.eclipse.sisu.plexus\\0.3.2\\org.eclipse.sisu.plexus-0.3.2.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\enterprise\\cdi-api\\1.0\\cdi-api-1.0.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\annotation\\jsr250-api\\1.0\\jsr250-api-1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\sisu\\org.eclipse.sisu.inject\\0.3.2\\org.eclipse.sisu.inject-0.3.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-component-annotations\\1.6\\plexus-component-annotations-1.6.jar;C:\\Users\\leysr\\.m2\\repository\\org\\sonatype\\plexus\\plexus-sec-dispatcher\\1.3\\plexus-sec-dispatcher-1.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\sonatype\\plexus\\plexus-cipher\\1.7\\plexus-cipher-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\slf4j\\slf4j-api\\1.7.5\\slf4j-api-1.7.5.jar;C:\\Users\\leysr\\.m2\\repository\\commons-cli\\commons-cli\\1.2\\commons-cli-1.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\commons\\commons-lang3\\3.4\\commons-lang3-3.4.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-suggest\\6.0.0\\lucene-suggest-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-analyzers-common\\6.0.0\\lucene-analyzers-common-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-core\\6.0.0\\lucene-core-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-misc\\6.0.0\\lucene-misc-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-queries\\6.0.0\\lucene-queries-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-queryparser\\6.0.0\\lucene-queryparser-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-sandbox\\6.0.0\\lucene-sandbox-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\mail\\mail\\1.4.7\\mail-1.4.7.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\activation\\activation\\1.1\\activation-1.1.jar;C:\\Users\\leysr\\git\\main\\scala\\xml\\ooxoo\\core\\master\\ooxoo-db\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\xml\\ooxoo\\core\\master\\ooxoo-db\\target\\test-classes;C:\\Users\\leysr\\git\\main\\scala\\xml\\ooxoo\\core\\master\\ooxoo-core\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\xml\\ooxoo\\core\\master\\ooxoo-core\\target\\test-classes;C:\\Users\\leysr\\git\\main\\scala\\utils\\tea\\master\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\utils\\tea\\master\\target\\test-classes;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\scala-reflect\\2.12.1\\scala-reflect-2.12.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\scala-compiler\\2.12.1\\scala-compiler-2.12.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\modules\\scala-xml_2.12\\1.0.6\\scala-xml_2.12-1.0.6.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalatest\\scalatest_2.12\\3.0.1\\scalatest_2.12-3.0.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalactic\\scalactic_2.12\\3.0.1\\scalactic_2.12-3.0.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\modules\\scala-parser-combinators_2.12\\1.0.4\\scala-parser-combinators_2.12-1.0.4.jar;C:\\Users\\leysr\\.m2\\repository\\net\\java\\dev\\stax-utils\\stax-utils\\20070216\\stax-utils-20070216.jar;C:\\Users\\leysr\\.m2\\repository\\org\\atteo\\evo-inflector\\1.2.1\\evo-inflector-1.2.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\commons\\commons-lang3\\3.3.2\\commons-lang3-3.3.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\modules\\scala-parser-combinators_2.12\\1.0.5\\scala-parser-combinators_2.12-1.0.5.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\modules\\scala-xml_2.12\\1.0.5\\scala-xml_2.12-1.0.5.jar;C:\\Users\\leysr\\git\\main\\indesign\\ide\\dev\\ide-agent\\target\\classes;C:\\Users\\leysr\\git\\main\\indesign\\ide\\dev\\ide-agent\\target\\test-classes;C:\\Users\\leysr\\git\\main\\scala\\wsb\\fwapp\\dev\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\wsb\\fwapp\\dev\\target\\test-classes;C:\\Users\\leysr\\git\\main\\scala\\wsb\\webapp\\master\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\wsb\\webapp\\master\\target\\test-classes;C:\\Users\\leysr\\git\\main\\scala\\wsb\\core\\master\\scala\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\wsb\\core\\master\\scala\\target\\test-classes;C:\\Users\\leysr\\.m2\\repository\\com\\sun\\faces\\jsf-api\\2.2.3\\jsf-api-2.2.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\commonjava\\googlecode\\markdown4j\\markdown4j\\2.2-cj-1.0\\markdown4j-2.2-cj-1.0.jar;C:\\Users\\leysr\\git\\main\\scala\\gui\\vui2\\core\\master\\vui2-html\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\gui\\vui2\\core\\master\\vui2-html\\target\\test-classes;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\vui2\\vui2-core\\2.1.1-SNAPSHOT\\vui2-core-2.1.1-SNAPSHOT.jar;C:\\Users\\leysr\\.m2\\repository\\org\\jsoup\\jsoup\\1.10.2\\jsoup-1.10.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\scalameta_2.12\\1.5.0\\scalameta_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\common_2.12\\1.5.0\\common_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\dialects_2.12\\1.5.0\\dialects_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\parsers_2.12\\1.5.0\\parsers_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\inputs_2.12\\1.5.0\\inputs_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\tokens_2.12\\1.5.0\\tokens_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\quasiquotes_2.12\\1.5.0\\quasiquotes_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\tokenizers_2.12\\1.5.0\\tokenizers_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\scalaparse_2.12\\0.4.2\\scalaparse_2.12-0.4.2.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\fastparse_2.12\\0.4.2\\fastparse_2.12-0.4.2.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\fastparse-utils_2.12\\0.4.2\\fastparse-utils_2.12-0.4.2.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\sourcecode_2.12\\0.1.3\\sourcecode_2.12-0.1.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\transversers_2.12\\1.5.0\\transversers_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\trees_2.12\\1.5.0\\trees_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\inline_2.12\\1.5.0\\inline_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\oauth-client\\google-oauth-client\\1.22.0\\google-oauth-client-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\http-client\\google-http-client\\1.22.0\\google-http-client-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\code\\findbugs\\jsr305\\1.3.9\\jsr305-1.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\api-client\\google-api-client\\1.22.0\\google-api-client-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\http-client\\google-http-client-jackson2\\1.22.0\\google-http-client-jackson2-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\fasterxml\\jackson\\core\\jackson-core\\2.1.3\\jackson-core-2.1.3.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\guava\\guava-jdk5\\17.0\\guava-jdk5-17.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-swing\\1.8\\batik-swing-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-anim\\1.8\\batik-anim-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-awt-util\\1.8\\batik-awt-util-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-bridge\\1.8\\batik-bridge-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-xml\\1.8\\batik-xml-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\xalan\\xalan\\2.7.0\\xalan-2.7.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-dom\\1.8\\batik-dom-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-ext\\1.8\\batik-ext-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-gui-util\\1.8\\batik-gui-util-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-script\\1.8\\batik-script-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-util\\1.8\\batik-util-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\xml-apis\\xml-apis\\1.3.04\\xml-apis-1.3.04.jar;C:\\Users\\leysr\\.m2\\repository\\xml-apis\\xml-apis-ext\\1.3.04\\xml-apis-ext-1.3.04.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-gvt\\1.8\\batik-gvt-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-svg-dom\\1.8\\batik-svg-dom-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-parser\\1.8\\batik-parser-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-css\\1.8\\batik-css-1.8.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\xmlgraphics-commons\\2.1\\xmlgraphics-commons-2.1.jar;C:\\Users\\leysr\\.m2\\repository\\commons-io\\commons-io\\1.3.1\\commons-io-1.3.1.jar;C:\\Users\\leysr\\.m2\\repository\\commons-logging\\commons-logging\\1.0.4\\commons-logging-1.0.4.jar";

	options[1].optionString =
			"-Dsun.boot.class.path=C:\\Users\\leysr\\eclipse\\scala-ide-4.6-RC1\\plugins\\org.scala-lang.scala-library_2.12.1.v20161205-104509-VFINAL-2787b47.jar;C:\\Users\\leysr\\eclipse\\scala-ide-4.6-RC1\\plugins\\org.scala-lang.scala-reflect_2.12.1.v20161205-104509-VFINAL-2787b47.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\lib\\resources.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\lib\\rt.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\lib\\sunrsasign.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\lib\\jsse.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\lib\\jce.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\lib\\charsets.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\lib\\jfr.jar;C:\\Program Files\\Java\\jdk1.8.0_112\\jre\\classes";
*/

	//options[0].optionString =
//				"-Djava.class.path=C:\\Users\\leysr\\git\\main\\eda\\hdl\\h2dl\\master\\indesign\\target\\classes;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\tcl\\tcl-interface\\1.0.0\\tcl-interface-1.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\nativelibs4java\\bridj-odfi\\0.7.1.odfi\\bridj-odfi-0.7.1.odfi.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\android\\tools\\dx\\1.7\\dx-1.7.jar;C:\\Users\\leysr\\git\\main\\indesign\\ide\\dev\\ide-core\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\wsb\\fwapp\\dev\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\xml\\ooxoo\\core\\master\\ooxoo-db\\target\\classes;C:\\Users\\leysr\\git\\main\\scala\\xml\\ooxoo\\core\\master\\ooxoo-core\\target\\classes;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\tea\\3.2.3\\tea-3.2.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\scala-compiler\\2.12.2\\scala-compiler-2.12.2.jar;C:\\Users\\leysr\\.m2\\repository\\net\\java\\dev\\stax-utils\\stax-utils\\20070216\\stax-utils-20070216.jar;C:\\Users\\leysr\\.m2\\repository\\org\\atteo\\evo-inflector\\1.2.1\\evo-inflector-1.2.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\hibernate\\hibernate-core\\5.2.10.Final\\hibernate-core-5.2.10.Final.jar;C:\\Users\\leysr\\.m2\\repository\\org\\jboss\\logging\\jboss-logging\\3.3.0.Final\\jboss-logging-3.3.0.Final.jar;C:\\Users\\leysr\\.m2\\repository\\org\\hibernate\\javax\\persistence\\hibernate-jpa-2.1-api\\1.0.0.Final\\hibernate-jpa-2.1-api-1.0.0.Final.jar;C:\\Users\\leysr\\.m2\\repository\\org\\javassist\\javassist\\3.20.0-GA\\javassist-3.20.0-GA.jar;C:\\Users\\leysr\\.m2\\repository\\antlr\\antlr\\2.7.7\\antlr-2.7.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\jboss\\spec\\javax\\transaction\\jboss-transaction-api_1.2_spec\\1.0.1.Final\\jboss-transaction-api_1.2_spec-1.0.1.Final.jar;C:\\Users\\leysr\\.m2\\repository\\org\\jboss\\jandex\\2.0.3.Final\\jandex-2.0.3.Final.jar;C:\\Users\\leysr\\.m2\\repository\\com\\fasterxml\\classmate\\1.3.0\\classmate-1.3.0.jar;C:\\Users\\leysr\\.m2\\repository\\dom4j\\dom4j\\1.6.1\\dom4j-1.6.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\hibernate\\common\\hibernate-commons-annotations\\5.0.1.Final\\hibernate-commons-annotations-5.0.1.Final.jar;C:\\Users\\leysr\\.m2\\repository\\com\\h2database\\h2\\1.4.195\\h2-1.4.195.jar;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\wsb\\wsb-webapp\\2.1.2\\wsb-webapp-2.1.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\wsb\\wsb-core\\3.3.1\\wsb-core-3.3.1.jar;C:\\Users\\leysr\\.m2\\repository\\com\\sun\\faces\\jsf-api\\2.2.3\\jsf-api-2.2.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\commonjava\\googlecode\\markdown4j\\markdown4j\\2.2-cj-1.0\\markdown4j-2.2-cj-1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\vui2\\vui2-html\\2.1.1\\vui2-html-2.1.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\odfi\\vui2\\vui2-core\\2.1.1\\vui2-core-2.1.1.jar;C:\\Users\\leysr\\.m2\\repository\\org\\jsoup\\jsoup\\1.10.2\\jsoup-1.10.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\scalameta_2.12\\1.5.0\\scalameta_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\common_2.12\\1.5.0\\common_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\dialects_2.12\\1.5.0\\dialects_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\parsers_2.12\\1.5.0\\parsers_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\inputs_2.12\\1.5.0\\inputs_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\tokens_2.12\\1.5.0\\tokens_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\quasiquotes_2.12\\1.5.0\\quasiquotes_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\tokenizers_2.12\\1.5.0\\tokenizers_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\scalaparse_2.12\\0.4.2\\scalaparse_2.12-0.4.2.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\fastparse_2.12\\0.4.2\\fastparse_2.12-0.4.2.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\fastparse-utils_2.12\\0.4.2\\fastparse-utils_2.12-0.4.2.jar;C:\\Users\\leysr\\.m2\\repository\\com\\lihaoyi\\sourcecode_2.12\\0.1.3\\sourcecode_2.12-0.1.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\transversers_2.12\\1.5.0\\transversers_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\trees_2.12\\1.5.0\\trees_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalameta\\inline_2.12\\1.5.0\\inline_2.12-1.5.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\oauth-client\\google-oauth-client\\1.22.0\\google-oauth-client-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\http-client\\google-http-client\\1.22.0\\google-http-client-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\code\\findbugs\\jsr305\\1.3.9\\jsr305-1.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\api-client\\google-api-client\\1.22.0\\google-api-client-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\http-client\\google-http-client-jackson2\\1.22.0\\google-http-client-jackson2-1.22.0.jar;C:\\Users\\leysr\\.m2\\repository\\com\\fasterxml\\jackson\\core\\jackson-core\\2.1.3\\jackson-core-2.1.3.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\guava\\guava-jdk5\\17.0\\guava-jdk5-17.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-swing\\1.7\\batik-swing-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-awt-util\\1.7\\batik-awt-util-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-bridge\\1.7\\batik-bridge-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-script\\1.7\\batik-script-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-js\\1.7\\batik-js-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-xml\\1.7\\batik-xml-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\xalan\\xalan\\2.6.0\\xalan-2.6.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-dom\\1.7\\batik-dom-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-ext\\1.7\\batik-ext-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-gui-util\\1.7\\batik-gui-util-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-util\\1.7\\batik-util-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\xml-apis\\xml-apis\\1.3.04\\xml-apis-1.3.04.jar;C:\\Users\\leysr\\.m2\\repository\\xml-apis\\xml-apis-ext\\1.3.04\\xml-apis-ext-1.3.04.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-gvt\\1.7\\batik-gvt-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-svg-dom\\1.7\\batik-svg-dom-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-anim\\1.7\\batik-anim-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-parser\\1.7\\batik-parser-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\batik-css\\1.7\\batik-css-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\xmlgraphics\\xmlgraphics-commons\\2.1\\xmlgraphics-commons-2.1.jar;C:\\Users\\leysr\\.m2\\repository\\commons-io\\commons-io\\1.3.1\\commons-io-1.3.1.jar;C:\\Users\\leysr\\.m2\\repository\\commons-logging\\commons-logging\\1.0.4\\commons-logging-1.0.4.jar;C:\\Users\\leysr\\git\\main\\indesign\\core\\master\\indesign-core\\target\\classes;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-util\\1.1.0\\aether-util-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-api\\1.1.0\\aether-api-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-transport-file\\1.1.0\\aether-transport-file-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-spi\\1.1.0\\aether-spi-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-transport-http\\1.1.0\\aether-transport-http-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\httpcomponents\\httpclient\\4.3.5\\httpclient-4.3.5.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\httpcomponents\\httpcore\\4.3.2\\httpcore-4.3.2.jar;C:\\Users\\leysr\\.m2\\repository\\commons-codec\\commons-codec\\1.6\\commons-codec-1.6.jar;C:\\Users\\leysr\\.m2\\repository\\org\\slf4j\\jcl-over-slf4j\\1.6.2\\jcl-over-slf4j-1.6.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-connector-basic\\1.1.0\\aether-connector-basic-1.1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-embedder\\3.3.9\\maven-embedder-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-settings\\3.3.9\\maven-settings-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-core\\3.3.9\\maven-core-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-model\\3.3.9\\maven-model-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-settings-builder\\3.3.9\\maven-settings-builder-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-repository-metadata\\3.3.9\\maven-repository-metadata-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-artifact\\3.3.9\\maven-artifact-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-aether-provider\\3.3.9\\maven-aether-provider-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\aether\\aether-impl\\1.0.2.v20150114\\aether-impl-1.0.2.v20150114.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\inject\\guice\\4.0\\guice-4.0-no_aop.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\inject\\javax.inject\\1\\javax.inject-1.jar;C:\\Users\\leysr\\.m2\\repository\\aopalliance\\aopalliance\\1.0\\aopalliance-1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-interpolation\\1.21\\plexus-interpolation-1.21.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-plugin-api\\3.3.9\\maven-plugin-api-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-model-builder\\3.3.9\\maven-model-builder-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-builder-support\\3.3.9\\maven-builder-support-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\com\\google\\guava\\guava\\18.0\\guava-18.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\maven-compat\\3.3.9\\maven-compat-3.3.9.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\maven\\wagon\\wagon-provider-api\\2.10\\wagon-provider-api-2.10.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-utils\\3.0.22\\plexus-utils-3.0.22.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-classworlds\\2.5.2\\plexus-classworlds-2.5.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\sisu\\org.eclipse.sisu.plexus\\0.3.2\\org.eclipse.sisu.plexus-0.3.2.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\enterprise\\cdi-api\\1.0\\cdi-api-1.0.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\annotation\\jsr250-api\\1.0\\jsr250-api-1.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\eclipse\\sisu\\org.eclipse.sisu.inject\\0.3.2\\org.eclipse.sisu.inject-0.3.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\codehaus\\plexus\\plexus-component-annotations\\1.6\\plexus-component-annotations-1.6.jar;C:\\Users\\leysr\\.m2\\repository\\org\\sonatype\\plexus\\plexus-sec-dispatcher\\1.3\\plexus-sec-dispatcher-1.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\sonatype\\plexus\\plexus-cipher\\1.7\\plexus-cipher-1.7.jar;C:\\Users\\leysr\\.m2\\repository\\org\\slf4j\\slf4j-api\\1.7.5\\slf4j-api-1.7.5.jar;C:\\Users\\leysr\\.m2\\repository\\commons-cli\\commons-cli\\1.2\\commons-cli-1.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\commons\\commons-lang3\\3.4\\commons-lang3-3.4.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-suggest\\6.0.0\\lucene-suggest-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-analyzers-common\\6.0.0\\lucene-analyzers-common-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-core\\6.0.0\\lucene-core-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-misc\\6.0.0\\lucene-misc-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-queries\\6.0.0\\lucene-queries-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-queryparser\\6.0.0\\lucene-queryparser-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\org\\apache\\lucene\\lucene-sandbox\\6.0.0\\lucene-sandbox-6.0.0.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\mail\\mail\\1.4.7\\mail-1.4.7.jar;C:\\Users\\leysr\\.m2\\repository\\javax\\activation\\activation\\1.1\\activation-1.1.jar;C:\\Users\\leysr\\git\\main\\indesign\\ide\\dev\\ide-agent\\target\\classes;C:\\Users\\leysr\\.m2\\repository\\org\\scalatest\\scalatest_2.12\\3.0.3\\scalatest_2.12-3.0.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scalactic\\scalactic_2.12\\3.0.3\\scalactic_2.12-3.0.3.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\scala-reflect\\2.12.2\\scala-reflect-2.12.2.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\modules\\scala-xml_2.12\\1.0.5\\scala-xml_2.12-1.0.5.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\modules\\scala-parser-combinators_2.12\\1.0.4\\scala-parser-combinators_2.12-1.0.4.jar;C:\\Users\\leysr\\.m2\\repository\\org\\scala-lang\\scala-library\\2.12.2\\scala-library-2.12.2.jar";

	//std::string cp = std::string("-Djava.class.path=C:\\Users\\leysr\\git\\adl\\lectures\\dds\\current\\app\\target\\classes;")+cpContent;
	//options[0].optionString = (char*) cp.c_str();

	std::string cp = std::string("-Djava.class.path=")+cpContent;
	options[0].optionString = (char*) cp.c_str();
	std::cout << cp << std::endl;


	options[1].optionString = "-Xcheck:jni";

	//options[3].optionString = "-Djava.compiler=NONE";
	//options[4].optionString = "-verbose:gc";

	vm_args.nOptions = 2;

	//options[2].optionString = "-Djava.compiler=NONE";
	//options[2].optionString = "-XX:-TraceClassResolution";

	vm_args.version = JNI_VERSION_1_8;

	//jint argsCount = JNI_GetDefaultJavaVMInitArgs(&vm_args);

	//options[0].optionString = (char*) cpArgument.c_str();
	//vm_args.nOptions = 1;

	vm_args.options = options;
	vm_args.ignoreUnrecognized = false;

	int status = JNI_CreateJavaVM(&jvm, (void**) &env, &vm_args);
	delete options;

	// Register
	//----------------
	vpiRunObj = env->FindClass("vpi/VPIInterface$");
	if (vpiRunObj != NULL) {
		std::cout << "VPI Interface Found" << std::endl;
		env->RegisterNatives(vpiRunObj, &registerVPIChangeDef, 1);
		env->RegisterNatives(vpiRunObj, &writeVPIValueDef, 1);
		env->RegisterNatives(vpiRunObj, &readVPIValueIntDef, 1);
		env->RegisterNatives(vpiRunObj, &readVPIValueBinStrDef, 1);
	} else {
		std::cout << "VPI Interface Not Found" << std::endl;
	}



	// Run Main
	//-----------------

	if (status != JNI_ERR) {
		std::cout << "JVM creation successful, Main is: "<< mainName << std::endl;

		/* invoke the Main.test method using the JNI */
		//vpiRunObj = env->FindClass("kit/ipe/adl/dds/demo/CounterDemoVPI");
		vpiRunObj = env->FindClass((char*)mainName.c_str());
		if (vpiRunObj != NULL) {
			std::cout << "Main Class Found" << std::endl;

			jmethodID mid = env->GetStaticMethodID(vpiRunObj, "run",
			 "()V");
			/*jmethodID mid = env->GetStaticMethodID(vpiRunObj, "main",
					"([Ljava/lang/String;)V");*/

			if (mid != NULL) {
				std::cout << "Main Method found" << std::endl;

				env->CallStaticVoidMethod(vpiRunObj, mid);
				jthrowable err = env->ExceptionOccurred();
				if (err != NULL) {
					std::cout << "Error during run" << std::endl;
					env->ExceptionDescribe();

				} else {
					std::cout << "Finished run " << std::endl;
					/*jboolean copy = JNI_TRUE;
					 const char * chars = env->GetStringUTFChars(res, &copy);
					 std::cout << std::string(chars) << std::endl;*/
				}

			} else {
				std::cout << "Main Method not found" << std::endl;
			}

		} else {
			std::cout << "Main Class not Found" << std::endl;
		}

	} else {
		std::cout << "JVM creation not successful" << std::endl;
	}

	return 1;
}

static int stopJava(struct t_cb_data *) {

	jvm->DestroyJavaVM();

}

// Start DB
//-------------

void demo_bootstrap() {

	// Register System Task
	//--------------------------
	/*s_vpi_systf_data tf_data;

	 tf_data.type = vpiSysTask;
	 tf_data.tfname = "$hello";
	 tf_data.calltf = hello_calltf;
	 tf_data.compiletf = hello_compiletf;
	 tf_data.sizetf = 0;
	 tf_data.user_data = 0;
	 vpi_register_systf(&tf_data);*/

	// CallBack
	///-------------------------
	startupCallBackDef.obj = NULL;
	startupCallBackDef.cb_rtn = startJava;
	startupCallBackDef.reason = cbStartOfSimulation;
	startupCallBackDef.value = &startupCallBackValue;
	startupCallBackDef.time = &startupCallBackTime;

	vpi_register_cb(&startupCallBackDef);

}

void (*vlog_startup_routines[])() = {
	demo_bootstrap,
	0
};
