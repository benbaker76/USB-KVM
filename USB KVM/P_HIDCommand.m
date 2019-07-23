//
//  P_HIDCommand.m
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "P_HIDCommand.h"
#import "HID_Utilities.h"
#include <IOKit/hid/IOHIDLib.h>

@implementation P_HIDCommand

-(id)initWithDeviceRef:(io_object_t)deviceRef
{
	self = [super init];
	
	if(self)
	{
		kern_return_t result;
		CFMutableDictionaryRef properties;
		
		RecElement *recElement = NULL;
		m_deviceRef = deviceRef;
		m_addAsChild = YES;
		
		memset(&m_recDevice, 0, sizeof(RecDevice));
		
		if ((result = IORegistryEntryCreateCFProperties(deviceRef, &properties, kCFAllocatorDefault, 0)) == kIOReturnSuccess)
		{
			NSMutableDictionary *propertiesDictionary = (__bridge NSMutableDictionary *)properties;
			
			[self hidGetCollectionElements:propertiesDictionary recElement:&recElement];

			m_recDevice.vendorID = [propertiesDictionary objectForKey:@"VendorID"];
			m_recDevice.productID = [propertiesDictionary objectForKey:@"ProductID"];
			m_recDevice.locationID = [propertiesDictionary objectForKey:@"LocationID"];
			m_recDevice.productName = [propertiesDictionary objectForKey:@"Product"];
			m_recDevice.maxOutputReportSize = [[propertiesDictionary objectForKey:@"MaxOutputReportSize"] intValue];
			
			CFRelease(properties);
		}
	}
	
	return self;
}

-(void)dealloc
{
	[self hidCloseReleaseInterface];
	[self hidDisposeDeviceElements:m_recDevice.pListElements];
	
	if (m_recDevice.vendorID)
		[m_recDevice.vendorID release];
	if (m_recDevice.productID)
		[m_recDevice.productID release];
	if (m_recDevice.locationID)
		[m_recDevice.locationID release];
	if (m_recDevice.productName)
		[m_recDevice.productName release];
	
	[super dealloc];
}

-(char)start
{
	m_hidRunLoopRef = 0;
	int value;
	[NSThread detachNewThreadSelector:@selector(createHIDInterfaces:) toTarget:self withObject:[NSNumber numberWithInt:&value]];
	
	while (!m_hidRunLoopRef)
		usleep(100000);
	
	return (value == 0);
}

-(void)stop
{
	if (m_hidRunLoopRef)
	{
		CFRunLoopStop(m_hidRunLoopRef);
		
		while (m_hidRunLoopRef)
			usleep(100000);
	}
	
	[self removeOutputElementFromQueue:&m_recDevice.outputElements];
	[self removeElementFromQueue:&m_recDevice.queueElements];
	[self hidCloseReleaseInterface];
}

-(NSString *)vendorID
{
	return [[m_recDevice.vendorID copy] autorelease];
}

-(NSString *)productID
{
	return [[m_recDevice.productID copy] autorelease];
}

-(NSString *)locationID
{
	return [[m_recDevice.locationID copy] autorelease];
}

-(NSString *)productName
{
	return [[m_recDevice.productName copy] autorelease];
}

-(uint32_t)maxOutputReportSize
{
	return m_recDevice.maxOutputReportSize;
}

-(io_object_t)deviceRef
{
	return m_deviceRef;
}

-(HRESULT)hidSetElementValue:(char *)value
{
	HRESULT result;
	IOHIDEventStruct event = { };
	
	RecElement *recElement = (RecElement *)[[m_recDevice.outputElements objectAtIndex:0] unsignedLongLongValue];
	
	if (!recElement || !m_recDevice.outputTransaction)
		return 0xE00002BC;
	
	event.type = recElement->type;
	event.elementCookie = recElement->cookie;
	event.value = value[0];
	
	result = (*m_recDevice.outputTransaction)->setElementValue(m_recDevice.outputTransaction, recElement->cookie, &event);

	if (result == kIOReturnSuccess)
	{
		recElement = (RecElement *)[[m_recDevice.outputElements objectAtIndex:1] unsignedLongLongValue];
		event.type = recElement->type;
		event.elementCookie = recElement->cookie;
		event.value = (value[3] << 16) | value[1];
		
		result = (*m_recDevice.outputTransaction)->setElementValue(m_recDevice.outputTransaction, recElement->cookie, &event);

		if (result == kIOReturnSuccess)
			result = (*m_recDevice.outputTransaction)->commit(m_recDevice.outputTransaction, 0, 0, 0, 0);
	}
	
	return result;
}

-(HRESULT)hidGetElementValueAndCookie:(char *)value cookie:(IOHIDElementCookie *)cookie timestamp:(AbsoluteTime *)timestamp
{
	HRESULT result = 0xE00002C0;
	IOHIDEventStruct event = { };
	AbsoluteTime maxTime = { };

	if (m_recDevice.queue)
	{
		result = (*m_recDevice.queue)->getNextEvent(m_recDevice.queue, &event, maxTime, 0);
		
		if (result == kIOReturnSuccess)
		{
			memcpy(value, &event.value, 4);
			*cookie = event.elementCookie;
			timestamp->lo = event.timestamp.lo;
			timestamp->hi = event.timestamp.hi;
		}
	}
	
	return result;
}

-(HRESULT)hidGetElementValue:(RecElement *)recElement
{
	IOHIDEventStruct event = { };
	HRESULT result;
	
	if (!recElement)
		return 0;
	
	if (!m_recDevice.interface || (result = (*m_recDevice.interface)->getElementValue(m_recDevice.interface, recElement->cookie, &event)))
		return 0;
	
	if (result < recElement->minReport)
		recElement->minReport = result;
	
	if (result > recElement->maxReport)
		recElement->maxReport = result;
	
	return result;
}

-(void)hidGetCollectionElements:(NSMutableDictionary *)dictionary recElement:(RecElement **)recElement
{
	id elementsArray = [dictionary objectForKey:@"Elements"];
	
	if (elementsArray)
		[self hidGetElements:elementsArray recElement:recElement];
}

-(void)hidGetElements:(id)value recElement:(RecElement **)recElement
{
	if ([value isKindOfClass:[NSMutableArray class]])
	{
		NSMutableArray *array = (NSMutableArray *)value;
		
		for (int i = 0; i < [array count]; i++)
			[self hidGetElementsNSArrayHandler:[array objectAtIndex:i] withObject:recElement];
	}
}

-(void)hidGetElementsNSArrayHandler:(id)value withObject:(RecElement **)recElement
{
	if ([value isKindOfClass:[NSMutableDictionary class]])
		[self hidAddElement:value recElement:recElement];
}

-(void)hidAddElement:(NSMutableDictionary *)value recElement:(RecElement **)recElement
{
	IOHIDElementType type;
	uint16_t usagePage;
	uint16_t usage;
	RecElement *recElementTemp = NULL;
	
	type = [[value objectForKey:@"Type"] intValue];
	usagePage = [[value objectForKey:@"UsagePage"] intValue];
	usage = [[value objectForKey:@"Usage"] intValue];
	
	if (type)
	{
		if (type == kIOHIDElementTypeCollection)
			goto LABEL_1;
		if (!usagePage)
			goto LABEL_2;
		if (usagePage != 1)
		{
			if (usagePage == 9)
			{
				recElementTemp = (RecElement *)NSAllocateMemoryPages(sizeof(RecElement));
				if (recElementTemp)
					++m_recDevice.buttons;
				goto LABEL_2;
			}
LABEL_1:
			recElementTemp = (RecElement *)NSAllocateMemoryPages(sizeof(RecElement));
			goto LABEL_2;
		}
		switch (usage)
		{
			case 0x30:
			case 0x31:
			case 0x32:
			case 0x33:
			case 0x34:
			case 0x35:
				recElementTemp = (RecElement *)NSAllocateMemoryPages(sizeof(RecElement));
				if (recElementTemp)
					++m_recDevice.axis;
				break;
			case 0x36:
				recElementTemp = (RecElement *)NSAllocateMemoryPages(sizeof(RecElement));
				if (recElementTemp)
					++m_recDevice.sliders;
				break;
			case 0x37:
				recElementTemp = (RecElement *)NSAllocateMemoryPages(sizeof(RecElement));
				if (recElementTemp)
					++m_recDevice.dials;
				break;
			case 0x38:
				recElementTemp = (RecElement *)NSAllocateMemoryPages(sizeof(RecElement));
				if (recElementTemp)
					++m_recDevice.wheels;
				break;
			case 0x39:
				recElementTemp = (RecElement *)NSAllocateMemoryPages(sizeof(RecElement));
				if (recElementTemp)
					++m_recDevice.hats;
				break;
			default:
				break;
		}
	}
LABEL_2:
	if (!recElementTemp)
		return;
	
	memset(recElementTemp, 0, sizeof(RecElement));
	
	recElementTemp->type = type;
	recElementTemp->usagePage = usagePage;
	recElementTemp->usage = usage;
	
	[self hidGetElementInfo:value recElement:recElementTemp];
	
	++m_recDevice.totalElements;
	
	if (recElementTemp->type == kIOHIDElementTypeOutput)
	{
		++m_recDevice.outputs;
	}
	else if (recElementTemp->type > 0x81)
	{
		if (recElementTemp->type == kIOHIDElementTypeFeature)
		{
			++m_recDevice.features;
		}
		else if (recElementTemp->type == kIOHIDElementTypeCollection)
		{
			++m_recDevice.collections;
		}
	}
	else if (recElementTemp->type <= 4)
	{
		++m_recDevice.inputs;
	}
	
	if (*recElement)
	{
		if (m_addAsChild)
		{
			while (true)
			{
				RecElement *recElementTemp2 = (*recElement)->pChild;
				
				if (!recElementTemp2)
					break;
				
				*recElement = recElementTemp2;
			}
			
			(*recElement)->pChild = recElementTemp;
		}
		else
		{
			while (true)
			{
				RecElement *recElementTemp2 = (*recElement)->pSibling;
				
				if (!recElementTemp2)
					break;
				
				*recElement = recElementTemp2;
			}
			
			(*recElement)->pSibling = recElementTemp;
		}
		
		recElementTemp->pPrevious = *recElement;
		*recElement = recElementTemp;
		
		if (type != kIOHIDElementTypeCollection)
			goto LABEL_4;
		
		goto LABEL_3;
	}
	m_recDevice.pListElements = recElementTemp;
	*recElement = recElementTemp;
	if (type == kIOHIDElementTypeCollection)
	{
LABEL_3:
		m_addAsChild = YES;
		[self hidGetCollectionElements:value recElement:&recElementTemp];
	}
LABEL_4:
	m_addAsChild = NO;
}

-(void)hidGetElementInfo:(NSDictionary *)value recElement:(RecElement *)recElement
{
	recElement->cookie = [[value objectForKey:@"ElementCookie"] intValue];
	recElement->min = [[value objectForKey:@"Min"] intValue];
	recElement->maxReport = [[value objectForKey:@"Min"] intValue];
	recElement->userMin = 0;
	recElement->max = [[value objectForKey:@"Max"] intValue];
	recElement->minReport = [[value objectForKey:@"Max"] intValue];
	recElement->userMax = 255;
	recElement->scaledMin =  [[value objectForKey:@"ScaledMin"] intValue];
	recElement->scaledMax = [[value objectForKey:@"ScaledMax"] intValue];
	recElement->size = [[value objectForKey:@"Size"] intValue];
	recElement->relative = [[value objectForKey:@"IsRelative"] boolValue];
	recElement->wrapping = [[value objectForKey:@"IsWrapping"] boolValue];
	recElement->nonLinear = [[value objectForKey:@"IsNonLinear"] boolValue];
	recElement->preferredState = [[value objectForKey:@"HasPreferredState"] boolValue];
	recElement->nullState = [[value objectForKey:@"HasNullState"] boolValue];
	recElement->units = [[value objectForKey:@"Unit"] intValue];
	recElement->unitExp =  [[value objectForKey:@"UnitExponent"] intValue];
	
	NSString *product = [value objectForKey:@"Product"];
	
	if (product)
	{
		strcpy((char *)recElement->name, [product UTF8String]);
	}
	
	if (!recElement->name[0])
	{
		HIDGetUsageName(recElement->usagePage, recElement->usage, (char *)recElement->name);
		
		if (!recElement->name[0])
			strcpy((char *)recElement->name, "Element");
	}
}

-(void)hidDisposeDeviceElements:(RecElement *)recElement
{
	if (recElement)
	{
		if (recElement->pChild)
			[self hidDisposeDeviceElements:recElement->pChild];
		
		if (recElement->pSibling)
			[self hidDisposeDeviceElements:recElement->pSibling];
		
		NSDeallocateMemoryPages(recElement, sizeof(RecElement));
	}
}

-(RecElement *)getElement:(RecElement *)recElement usagePage:(uint16_t)usagePage usage:(uint16_t)usage type:(uint16_t)type elementCount:(char *)elementList
{
	RecElement *recElementTemp = nil;
	
	while (recElementTemp == nil && recElement != nil)
	{
		if (type != recElement->type || usagePage != recElement->usagePage || usage != recElement->usage)
		{
			if (recElement->pChild)
				recElementTemp = [self getElement:recElement->pChild usagePage:usagePage usage:usage type:type elementCount:elementList];
			
			if (!recElementTemp && recElement->pSibling)
				recElementTemp = [self getElement:recElement->pSibling usagePage:usagePage usage:usage type:type elementCount:elementList];
		}
		else
			recElementTemp = recElement;
	}
	
	return recElementTemp;
}

-(void)createHIDInterfaces:(NSNumber *)value
{
	NSAutoreleasePool *pool;
	kern_return_t result;
	CFRunLoopSourceRef runLoopSourceRef;
	BOOL found = NO;
	
	pool = [NSAutoreleasePool new];
	result = [self hidCreateOpenDeviceInterface:m_deviceRef runLoopRef:CFRunLoopGetCurrent() runLoopSourceRef:&runLoopSourceRef];
	
	if (result == kIOReturnSuccess)
	{
		[self queueElement:m_recDevice.pListElements elementList:&m_recDevice.queueElements found:&found];
		found = NO;
		[self queueOutputElement:m_recDevice.pListElements elementList:&m_recDevice.outputElements found:&found];
	}
	
	m_hidRunLoopRef = CFRunLoopGetCurrent();
	CFRunLoopRun();
	CFRunLoopRemoveSource(m_hidRunLoopRef, runLoopSourceRef, kCFRunLoopDefaultMode);
	m_hidRunLoopRef = 0;
	[pool release];
}

void hidQueueEventCallback(void *target, IOReturn result, void *refcon, void *sender)
{
	P_HIDCommand *hidCommand = (__bridge P_HIDCommand *)target;
	
	[hidCommand queueEventCallback];
}

-(void)queueEventCallback
{
}

-(kern_return_t) hidCreateOpenDeviceInterface:(io_service_t)service runLoopRef:(CFRunLoopRef)runLoop runLoopSourceRef:(CFRunLoopSourceRef *)runLoopSource
{
	kern_return_t result = 0xE00002C0;
	IOCFPlugInInterface **plugInInterface;
	int score;
	
	score = 0;
	plugInInterface = 0;
	
	if (!m_recDevice.interface)
	{
		result = IOCreatePlugInInterfaceForService(service, kIOHIDDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
		
		if (result == kIOReturnSuccess)
		{
			result = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID), (LPVOID *)&m_recDevice.interface);
			IODestroyPlugInInterface(plugInInterface);
			
			if (result == kIOReturnSuccess)
			{
				int i = 0;
				result = 0xE00002CD;
				
				if (!m_recDevice.interface)
					return kIOReturnSuccess;
				
				while (result != kIOReturnSuccess && i < 10)
				{
					result = (*m_recDevice.interface)->open(m_recDevice.interface, 0);
					
					if (result == 0xE00002C5)
						return result;
					
					if (result)
						usleep(1000000);
					
					i++;
				}
				
				if (result == kIOReturnSuccess)
				{
					if (!m_recDevice.interface)
						return kIOReturnSuccess;
					
					m_recDevice.queue = (IOHIDQueueInterface **)(*m_recDevice.interface)->allocQueue(m_recDevice.interface);
					
					if (!m_recDevice.queue
						|| ((result = (*m_recDevice.queue)->create(m_recDevice.queue, 0, 50)) == kIOReturnSuccess
						&& (result = (*m_recDevice.queue)->createAsyncEventSource(m_recDevice.queue, runLoopSource)) == kIOReturnSuccess
						&& (CFRunLoopAddSource(runLoop, *runLoopSource, kCFRunLoopDefaultMode),
							(result = (*m_recDevice.queue)->setEventCallout(m_recDevice.queue, hidQueueEventCallback, self, 0)) == kIOReturnSuccess)))
					{
						m_recDevice.outputTransaction = (*m_recDevice.interface)->allocOutputTransaction(m_recDevice.interface);
						
						if (m_recDevice.outputTransaction)
							return (*m_recDevice.outputTransaction)->create(m_recDevice.outputTransaction);
						
						return kIOReturnSuccess;
					}
				}
			}
		}
	}
	
	return result;
}

-(void)hidCloseReleaseInterface
{
	if (m_recDevice.outputTransaction)
	{
		(*m_recDevice.outputTransaction)->dispose(m_recDevice.outputTransaction);
		(*m_recDevice.outputTransaction)->Release(m_recDevice.outputTransaction);
		m_recDevice.outputTransaction = 0;
	}
	if (m_recDevice.queue)
	{
		(*m_recDevice.queue)->stop(m_recDevice.queue);
		(*m_recDevice.queue)->dispose(m_recDevice.queue);
		(*m_recDevice.queue)->Release(m_recDevice.queue);
		m_recDevice.queue = 0;
	}
	if (m_recDevice.interface)
	{
		(*m_recDevice.interface)->close(m_recDevice.interface);
		(*m_recDevice.interface)->Release(m_recDevice.interface);
		m_recDevice.interface = 0;
	}
}

-(int)hidQueueElement:(RecElement *)recElement
{
	HRESULT result = 0xE00002C2;

	if (recElement)
	{
		if (m_recDevice.interface && m_recDevice.queue)
		{
			result = (*m_recDevice.queue)->stop(m_recDevice.queue);
			
			if (result == kIOReturnSuccess)
			{
				if ((*m_recDevice.queue)->hasElement(m_recDevice.queue, recElement->cookie) || (result = (*m_recDevice.queue)->addElement(m_recDevice.queue, recElement->cookie, 0)) == kIOReturnSuccess)
				{
					result = (*m_recDevice.queue)->start(m_recDevice.queue);
				}
			}
		}
		else
			result = 0xE00002BC;
	}
	
	return result;
}

-(int)hidDequeueElement:(RecElement *)recElement
{
	HRESULT result = 0xE00002C2;

	if (recElement)
	{
		if (m_recDevice.interface && m_recDevice.queue)
		{
			result = (*m_recDevice.queue)->stop(m_recDevice.queue);
			
			if (result == kIOReturnSuccess)
			{
				if (!(*m_recDevice.queue)->hasElement(m_recDevice.queue, recElement->cookie) || (result = (*m_recDevice.queue)->removeElement(m_recDevice.queue, recElement->cookie)) == kIOReturnSuccess)
					result = (*m_recDevice.queue)->start(m_recDevice.queue);
			}
		}
		else
			result = 0;
	}
	
	return result;
}

-(int)hidQueueOutputElement:(RecElement *)recElement
{
	HRESULT result = 0xE00002C2;
	Boolean hasElement;
	
	if (recElement)
	{
		if (m_recDevice.interface && m_recDevice.outputTransaction)
		{
			hasElement = (*m_recDevice.outputTransaction)->hasElement(m_recDevice.outputTransaction, recElement->cookie);
			
			result = kIOReturnSuccess;
			
			if (!hasElement)
				return (*m_recDevice.outputTransaction)->addElement(m_recDevice.outputTransaction, recElement->cookie);
		}
		else
			result = 0xE00002BC;
	}
	
	return result;
}

-(int)hidDequeueOutputElement:(RecElement *)recElement
{
	HRESULT result = 0xE00002C2;
	
	if (recElement)
	{
		if (m_recDevice.interface && m_recDevice.outputTransaction && (*m_recDevice.outputTransaction)->hasElement(m_recDevice.outputTransaction, recElement->cookie))
			result = (*m_recDevice.outputTransaction)->removeElement(m_recDevice.outputTransaction, recElement->cookie);
		else
			result = kIOReturnSuccess;
	}
	
	return result;
}

-(void)queueElement:(RecElement *)recElement elementList:(NSMutableArray **)elementList found:(BOOL *)found
{
	if (recElement)
	{
		if (recElement->type == 0x1 && recElement->usagePage == 0xFF01 && ![self hidQueueElement:recElement])
		{
			if (*elementList || (*elementList = [[NSMutableArray alloc] initWithCapacity:2]))
				[*elementList addObject:[NSNumber numberWithUnsignedLongLong:recElement]];
			
			if (recElement->size == 24)
				*found = YES;
		}
		
		if (!*found)
		{
			if (recElement->pChild)
				[self queueElement:recElement->pChild elementList:elementList found:found];

			if (!*found)
			{
				if (recElement->pSibling)
					[self queueElement:recElement->pSibling elementList:elementList found:found];
			}
		}
	}
}

-(void)removeElementFromQueue:(NSMutableArray **)elementList
{
	if (*elementList)
	{
		while (true)
		{
			NSNumber *element = [*elementList lastObject];
			
			if (!element)
				break;

			[self hidDequeueElement:[element unsignedLongLongValue]];
			
			[*elementList removeLastObject];
		}
		
		[*elementList release];
		*elementList = nil;
	}
}

-(void)queueOutputElement:(RecElement *)recElement elementList:(NSMutableArray **)elementList found:(BOOL *)found
{
	if (recElement)
	{
		if (recElement->type == 0x81 && recElement->usagePage == 0xFF01 && ![self hidQueueOutputElement:recElement])
		{
			if (*elementList || (*elementList = [[NSMutableArray alloc] initWithCapacity:2]))
				[*elementList addObject:[NSNumber numberWithUnsignedLongLong:recElement]];
			
			if (recElement->size == 24)
				*found = YES;
		}
		
		if (!*found)
		{
			if (recElement->pChild)
				[self queueOutputElement:recElement->pChild elementList:elementList found:found];
			
			if (!*found)
			{
				if (recElement->pSibling)
					[self queueOutputElement:recElement->pSibling elementList:elementList found:found];
			}
		}
	}
}

-(void)removeOutputElementFromQueue:(NSMutableArray **)elementList
{
	if (*elementList)
	{
		while (true)
		{
			NSNumber *element = [*elementList lastObject];
			
			if (!element)
				break;
			
			[self hidDequeueOutputElement:[element unsignedLongLongValue]];
			[*elementList removeLastObject];
		}
		
		[*elementList release];
		*elementList = 0;
	}
}

@end
